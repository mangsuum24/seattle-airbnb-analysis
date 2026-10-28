-- =====================================================================
-- Seattle Airbnb Market Analysis: What Drives Pricing?
-- File 2 of 3: cleaning.sql
-- How I found the outliers, and the clean_listings view that every
-- analysis query is built on.
-- =====================================================================


-- ---------------------------------------------------------------------
-- STEP 1: First look at the raw summary data
-- ---------------------------------------------------------------------

-- How big is the dataset?
SELECT
    COUNT(*)                            AS total_listings,
    COUNT(price)                        AS listings_with_price,
    COUNT(DISTINCT neighbourhood_group) AS total_boroughs,
    COUNT(DISTINCT neighbourhood)       AS total_neighbourhoods,
    COUNT(DISTINCT host_id)             AS total_hosts
FROM listingsSEA;
-- Result: 6,996 listings | 6,221 with a price | 17 neighbourhood groups
--         88 neighbourhoods | 3,558 hosts


-- What's the price range?
SELECT
    MIN(price)                                          AS lowest_price,
    MAX(price)                                          AS highest_price,
    ROUND(AVG(price), 2)                                AS avg_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)  AS median_price
FROM listingsSEA
WHERE price IS NOT NULL AND price > 0;
-- Result: min $15 | max $50,039 | avg $571.72 | median $149
-- Red flag: the average is almost 4x the median, so a few extreme
-- listings are pulling the mean up.


-- ---------------------------------------------------------------------
-- STEP 2: Find where the outliers are
-- ---------------------------------------------------------------------

-- How many listings are extreme outliers?
SELECT
    CASE
        WHEN price <= 100  THEN '$1-100'
        WHEN price <= 200  THEN '$101-200'
        WHEN price <= 500  THEN '$201-500'
        WHEN price <= 1000 THEN '$501-1000'
        ELSE '$1000+'
    END AS price_range,
    COUNT(*) AS total_listings,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS percentage
FROM listingsSEA
WHERE price IS NOT NULL AND price > 0
GROUP BY price_range
ORDER BY price_range;
-- Result: 49.6% of listings are $101-200; only 3.6% are above $500.


-- Neighbourhood group x room type (two-dimensional breakdown)
SELECT
    neighbourhood_group,
    room_type,
    COUNT(*)                                            AS listings,
    ROUND(AVG(price), 2)                                AS avg_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)  AS median_price
FROM listingsSEA
WHERE price IS NOT NULL AND price > 0
GROUP BY neighbourhood_group, room_type
ORDER BY neighbourhood_group, avg_price DESC;
-- Result: Downtown "Hotel room" = 48 listings, avg $43,989, median $40,100.
-- That is not a real nightly rate.


-- Inspect the Downtown hotel-room listings
SELECT id, name, host_name, price, minimum_nights
FROM listingsSEA
WHERE neighbourhood_group = 'Downtown'
  AND room_type = 'Hotel room'
ORDER BY price DESC;
-- Result: all 48 belong to two operators (RoomPicks and Aishat), priced
-- $40,000-$50,000 per night, several advertising multi-unit bundles.
-- The same hosts also had "Entire home/apt" listings at $40,000-$50,000.
-- These are bulk or commercial inventory, not comparable market listings.
-- Separate issue: listings with 30-180 night minimums are long-term
-- leases, not short-term rentals.


-- ---------------------------------------------------------------------
-- STEP 3: The clean_listings view (built on the detailed table)
-- ---------------------------------------------------------------------
CREATE VIEW clean_listings AS
SELECT *
FROM listings_sea_detailed
WHERE price IS NOT NULL            -- Exclude missing prices
  AND price > 0                    -- Exclude zero-dollar listings
  AND price < 1000                 -- Exclude bogus/inflated prices
  AND room_type != 'Hotel room'    -- Exclude commercial hotel inventory
  AND minimum_nights <= 30;        -- Exclude long-term leases

-- Cleaning decisions
-- | Rule                 | Rows | Reason                                          |
-- |----------------------|------|-------------------------------------------------|
-- | NULL or $0 price     | 775  | Can't be used in pricing analysis               |
-- | Price >= $1,000      | 91   | Bulk-package listings from two hosts            |
-- | Room type = Hotel    | ~51  | Commercial hotel inventory (same two hosts)     |
-- | Minimum nights > 30  | 342  | Monthly rentals, not the short-term market      |
-- | Total (rules overlap)| 1,208| About 17% of raw rows excluded                  |


-- Check the impact of cleaning
SELECT
    COUNT(*)                                            AS listings,
    ROUND(AVG(price), 2)                                AS avg_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)  AS median_price
FROM clean_listings;
-- Result: 5,788 listings | avg ~$170 | median ~$145
-- The average dropped about 70% while the median barely moved, which
-- confirms the outliers were distorting the mean, not the core market.
