-- =====================================================================
-- Seattle Airbnb Market Analysis: What Drives Pricing?
-- File 1 of 3: create_tables.sql
-- Database: PostgreSQL (pgAdmin 4)
-- Source:   Inside Airbnb, Seattle, WA (https://insideairbnb.com/get-the-data/)
-- =====================================================================


-- ---------------------------------------------------------------------
-- Table 1: listingsSEA
-- Summary file (listings.csv), 18 columns. Used for the first look
-- at the market and to discover the price outliers.
-- ---------------------------------------------------------------------
CREATE TABLE listingsSEA (
    id                              BIGINT PRIMARY KEY,
    name                            TEXT,
    host_id                         BIGINT,
    host_name                       TEXT,
    neighbourhood_group             TEXT,
    neighbourhood                   TEXT,
    latitude                        DECIMAL(10,5),
    longitude                       DECIMAL(10,5),
    room_type                       TEXT,
    price                           INT,
    minimum_nights                  INT,
    number_of_reviews               INT,
    last_review                     DATE,
    reviews_per_month               DECIMAL(5,2),
    calculated_host_listings_count  INT,
    availability_365                INT,
    number_of_reviews_ltm           INT,
    license                         TEXT
);


-- ---------------------------------------------------------------------
-- Table 2: listings_sea_detailed
-- Detailed file (listings.csv.gz, extracted with 7-Zip), 70+ columns.
-- I kept the 35 columns needed for pricing analysis: property features
-- (bedrooms, bathrooms, accommodates), host quality (superhost,
-- response time), review scores, and estimated revenue/occupancy.
--
-- Pre-load cleaning: host_response_rate and host_acceptance_rate had
-- "N/A" and blank values. I cleaned them and regenerated the CSV
-- so they would import as INT.
-- ---------------------------------------------------------------------
CREATE TABLE listings_sea_detailed (
    id                              BIGINT PRIMARY KEY,
    name                            TEXT,
    host_id                         BIGINT,
    host_name                       TEXT,
    host_since                      DATE,
    host_response_time              TEXT,
    host_response_rate              INT,
    host_acceptance_rate            INT,
    host_is_superhost               TEXT,
    host_identity_verified          TEXT,
    neighbourhood                   TEXT,
    neighbourhood_group             TEXT,
    latitude                        DECIMAL(10,5),
    longitude                       DECIMAL(10,5),
    property_type                   TEXT,
    room_type                       TEXT,
    accommodates                    INT,
    bathrooms                       DECIMAL(3,1),
    bedrooms                        INT,
    beds                            INT,
    price                           DECIMAL(10,2),
    minimum_nights                  INT,
    availability_365                INT,
    number_of_reviews               INT,
    number_of_reviews_ltm           INT,
    reviews_per_month               DECIMAL(5,2),
    instant_bookable                TEXT,
    estimated_revenue_l365d         INT,
    estimated_occupancy_l365d       INT,
    review_scores_rating            DECIMAL(3,2),
    review_scores_cleanliness       DECIMAL(3,2),
    review_scores_location          DECIMAL(3,2),
    review_scores_value             DECIMAL(3,2),
    calculated_host_listings_count  INT
);

-- Import: pgAdmin > right-click table > Import/Export Data
--         Format: csv | Header: ON | Escape: "
