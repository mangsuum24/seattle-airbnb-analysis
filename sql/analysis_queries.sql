-- =====================================================================
-- Seattle Airbnb Market Analysis: What Drives Pricing?
-- File 3 of 3: analysis_queries.sql
-- All queries run against the clean_listings view (see cleaning.sql).
--
-- Business question: If someone wanted to list their home on Airbnb in
-- Seattle, what factors most influence the price they should charge?
-- =====================================================================


-- =====================================================================
-- SECTION 1: What physical features drive price?
-- =====================================================================

-- 1.1 Price by bedroom count (the clearest price relationship)
SELECT
    bedrooms,
    COUNT(*)                                            AS listings,
    ROUND(AVG(price), 2)                                AS avg_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)  AS median_price,
    ROUND(AVG(review_scores_rating), 2)                 AS avg_rating
FROM clean_listings
WHERE bedrooms IS NOT NULL
GROUP BY bedrooms
ORDER BY bedrooms;
-- Result: median $110 (1BR) -> $173 (2BR) -> $227 (3BR) -> $295 (4BR).
-- Each extra bedroom adds roughly $55-65 to the median nightly price.


-- 1.2 Price by guest capacity: do more guests mean a higher price?
SELECT
    accommodates,
    COUNT(*)                                            AS listings,
    ROUND(AVG(price), 2)                                AS avg_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)  AS median_price
FROM clean_listings
GROUP BY accommodates
ORDER BY accommodates;
-- Result: each extra guest adds roughly $25-30 in the 2-8 guest range.
-- Weaker than bedrooms: capacity can be padded with sofa beds.


-- 1.3 Price by bathroom count
SELECT
    bathrooms,
    COUNT(*)              AS listings,
    ROUND(AVG(price), 2)  AS avg_price
FROM clean_listings
WHERE bathrooms IS NOT NULL
GROUP BY bathrooms
ORDER BY bathrooms;
-- Result: 63% of listings have exactly 1 bath ($135 avg). Half-baths sit
-- between whole numbers (staircase pattern). 25 listings with 0 baths
-- averaging $212 look like a data-entry gap, not real properties.


-- 1.4 The money query: bedrooms + room type combined
-- This is what a new host actually needs to know.
SELECT
    room_type,
    bedrooms,
    COUNT(*)                                            AS listings,
    ROUND(AVG(price), 2)                                AS avg_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)  AS median_price
FROM clean_listings
WHERE bedrooms IS NOT NULL
GROUP BY room_type, bedrooms
HAVING COUNT(*) >= 10
ORDER BY room_type, bedrooms;
-- Result: 1BR entire home $126 median vs 1BR private room $74 (+70%).
-- 2BR entire home $175 vs 2BR private room $115.
-- Private rooms stop at about 2 bedrooms, so bedrooms only act as a
-- price lever for entire homes. Room type sets the tier; bedrooms
-- move you up within it.


-- =====================================================================
-- SECTION 2: Does being a better host let you charge more?
-- =====================================================================

-- 2.1 Superhost premium: do superhosts earn more?
SELECT
    host_is_superhost,
    COUNT(*)                                            AS listings,
    ROUND(AVG(price), 2)                                AS avg_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)  AS median_price,
    ROUND(AVG(review_scores_rating), 2)                 AS avg_rating,
    ROUND(AVG(estimated_revenue_l365d), 0)              AS avg_annual_revenue
FROM clean_listings
WHERE host_is_superhost IS NOT NULL
GROUP BY host_is_superhost;
-- Result: superhosts charge 12% more (median $150 vs $134)
-- but earn 2.5x the revenue ($24,380 vs $9,878).


-- 2.2 Instant bookable: convenience premium or discount?
SELECT
    instant_bookable,
    COUNT(*)                                AS listings,
    ROUND(AVG(price), 2)                    AS avg_price,
    ROUND(AVG(number_of_reviews_ltm), 1)    AS avg_recent_reviews,
    ROUND(AVG(estimated_revenue_l365d), 0)  AS avg_annual_revenue
FROM clean_listings
GROUP BY instant_bookable;
-- Result: instant-book listings charge MORE ($183 vs $169), get more
-- recent reviews (21.5 vs 18.6) and earn more ($19,779 vs $18,376).


-- 2.3 Host responsiveness: does a fast response mean a higher price?
SELECT
    host_response_time,
    COUNT(*)                                AS listings,
    ROUND(AVG(price), 2)                    AS avg_price,
    ROUND(AVG(review_scores_rating), 2)     AS avg_rating,
    ROUND(AVG(estimated_revenue_l365d), 0)  AS avg_annual_revenue
FROM clean_listings
WHERE host_response_time IS NOT NULL
GROUP BY host_response_time
ORDER BY avg_price DESC;
-- Result: "a few days or more" = highest price ($208) but lowest
-- revenue ($4,061). "Within an hour" = $175 and $20,572 (5x more).


-- =====================================================================
-- SECTION 3: Revenue vs price
-- =====================================================================

-- 3.1 Do expensive listings actually EARN more,
--     or do cheaper listings make it up in volume?
SELECT
    CASE
        WHEN price BETWEEN 1   AND 75  THEN '1_budget ($1-75)'
        WHEN price BETWEEN 76  AND 150 THEN '2_mid ($76-150)'
        WHEN price BETWEEN 151 AND 300 THEN '3_upper ($151-300)'
        ELSE '4_premium ($300+)'
    END AS price_tier,
    COUNT(*)                                    AS listings,
    ROUND(AVG(price), 2)                        AS avg_price,
    ROUND(AVG(estimated_occupancy_l365d), 0)    AS avg_nights_booked,
    ROUND(AVG(estimated_revenue_l365d), 0)      AS avg_annual_revenue,
    ROUND(AVG(reviews_per_month), 2)            AS avg_reviews_per_month
FROM clean_listings
WHERE estimated_revenue_l365d > 0
GROUP BY price_tier
ORDER BY price_tier;
-- Result: premium earns $40,697/yr on 101 nights; budget earns $7,230
-- on 128 nights (5.6x gap). Mid-tier has the most listings (2,074)
-- and the highest occupancy (153 nights).


-- 3.2 Top-earning neighbourhoods (by actual revenue, not just price)
SELECT
    neighbourhood_group,
    COUNT(*)                                    AS listings,
    ROUND(AVG(price), 2)                        AS avg_price,
    ROUND(AVG(estimated_revenue_l365d), 0)      AS avg_revenue,
    ROUND(AVG(estimated_occupancy_l365d), 0)    AS avg_nights_booked
FROM clean_listings
WHERE estimated_revenue_l365d > 0
GROUP BY neighbourhood_group
HAVING COUNT(*) >= 20
ORDER BY avg_revenue DESC;
-- Result: Queen Anne #1 ($29,950), Downtown #2 ($29,852) with the
-- highest occupancy (169 nights). Beacon Hill ranks 7th in revenue
-- despite being one of the cheaper areas. Top vs bottom gap: 2.3x.


-- =====================================================================
-- SECTION 4: Review scores and pricing
-- =====================================================================

-- 4.1 Do higher-rated listings charge more?
SELECT
    CASE
        WHEN review_scores_rating >= 4.9 THEN '1_exceptional (4.9-5.0)'
        WHEN review_scores_rating >= 4.7 THEN '2_excellent (4.7-4.89)'
        WHEN review_scores_rating >= 4.5 THEN '3_great (4.5-4.69)'
        WHEN review_scores_rating >= 4.0 THEN '4_good (4.0-4.49)'
        ELSE '5_below_avg (<4.0)'
    END AS rating_tier,
    COUNT(*)                                AS listings,
    ROUND(AVG(price), 2)                    AS avg_price,
    ROUND(AVG(estimated_revenue_l365d), 0)  AS avg_revenue
FROM clean_listings
WHERE review_scores_rating IS NOT NULL
GROUP BY rating_tier
ORDER BY rating_tier;
-- Result: price gap top vs bottom = 47% ($188 vs $128).
-- Revenue gap = 6.2x ($23,613 vs $3,799).
-- 83% of rated listings score 4.7+. Revenue falls off a cliff below
-- 4.7 ($21,252 -> $13,419).


-- 4.2 The "value perception" gap: what's overpriced vs underpriced?
-- Low value score + high price = overpriced in guests' eyes.
SELECT
    neighbourhood_group,
    ROUND(AVG(price), 2)                AS avg_price,
    ROUND(AVG(review_scores_value), 2)  AS avg_value_score,
    ROUND(AVG(price), 2)
        / NULLIF(ROUND(AVG(review_scores_value), 2), 0) AS price_per_value_point
FROM clean_listings
WHERE review_scores_value IS NOT NULL
GROUP BY neighbourhood_group
HAVING COUNT(*) >= 20
ORDER BY price_per_value_point DESC;
-- Result: value scores sit in a tight 4.46-4.82 band across all 16
-- areas. Cascade pays the 2nd-most per value point ($40.8) with one of
-- the lowest value scores (4.52). Delridge is the best deal ($26.6/point,
-- 4.81 score).


-- =====================================================================
-- SECTION 5: Window functions - each listing vs its competitive set
-- =====================================================================

-- 5.1 Compare every listing to listings with the same neighbourhood,
--     room type and bedroom count, and surface the biggest outliers.
SELECT
    name,
    neighbourhood_group,
    room_type,
    bedrooms,
    price,
    ROUND(AVG(price) OVER (
        PARTITION BY neighbourhood_group, room_type, bedrooms
    ), 2) AS comp_avg_price,
    price - ROUND(AVG(price) OVER (
        PARTITION BY neighbourhood_group, room_type, bedrooms
    ), 2) AS vs_competitors,
    COUNT(*) OVER (
        PARTITION BY neighbourhood_group, room_type, bedrooms
    ) AS comp_set_size
FROM clean_listings
WHERE bedrooms IS NOT NULL
ORDER BY ABS(price - AVG(price) OVER (
    PARTITION BY neighbourhood_group, room_type, bedrooms
)) DESC
LIMIT 30;
-- Result: a 2BR entire home in "Other neighborhoods" lists at $900
-- while its 320 comparable listings average $175 (5.1x the market).


-- =====================================================================
-- SECTION 6: The deliverable - pricing recommendation engine
-- "If you have X bedrooms in Y neighbourhood, here's what to charge."
-- =====================================================================

SELECT
    neighbourhood_group,
    room_type,
    bedrooms,
    COUNT(*)                                            AS comp_set_size,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) AS price_25th,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY price) AS price_median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) AS price_75th,
    ROUND(AVG(review_scores_rating), 2)                 AS avg_rating,
    ROUND(AVG(estimated_revenue_l365d), 0)              AS avg_revenue
FROM clean_listings
WHERE bedrooms IS NOT NULL
  AND estimated_revenue_l365d > 0
GROUP BY neighbourhood_group, room_type, bedrooms
HAVING COUNT(*) >= 5
ORDER BY neighbourhood_group, room_type, bedrooms;
-- Result example: 2BR entire home in Capitol Hill -> charge $155-$231,
-- with $187 (median) as the sweet spot (87 comparable listings).
-- Highest 3BR revenue: Cascade at ~$45,550/yr.
