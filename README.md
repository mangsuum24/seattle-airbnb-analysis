# Seattle Airbnb Market Analysis: What Drives Pricing?

## Project Overview

An exploratory data analysis of Seattle’s Airbnb market to identify the key factors that influence listing prices. This project answers a practical business question: if someone wanted to list their home on Airbnb in Seattle, what factors most influence the price they should charge?

The analysis examines pricing patterns across neighbourhoods, room types, host behavior, and demand signals using SQL queries on real-world data from Inside Airbnb.

---

## Key Findings

- Median nightly rate is **$149** vs. an average of **$571**, revealing significant right skew caused by luxury outliers
- **49.6%** of all listings are priced between **$101–$200/night**, while only **3.6%** exceed **$500/night**
- *(More findings will be added as the analysis progresses)*

---

## Tools & Technologies

| Tool | Purpose |
|------|---------|
| PostgreSQL | Database creation, data import, and SQL analysis |
| pgAdmin 4 | GUI for writing and executing SQL queries |
| Tableau Public | Interactive dashboard and data visualization |
| RStudio | Statistical modeling and regression analysis |
| Google Sheets | Initial data exploration |
| GitHub | Version control and project documentation |

---

## Data Source

- **Source:** [Inside Airbnb](http://insideairbnb.com/)
- **City:** Seattle, Washington, United States
- **Date:** December 4, 2025
- **License:** Creative Commons Attribution 4.0 International

### Dataset Files

| File | Description |
|------|-------------|
| `listings.csv` | Summary listing data — price, location, room type, reviews, availability |
| `reviews.csv` | Review dates per listing for time-based trend analysis |
| `neighbourhoods.csv` | Neighbourhood reference table for geographic filtering |

---

## Database Schema

```sql
CREATE TABLE listingsSEA (
    id BIGINT PRIMARY KEY,
    name TEXT,
    host_id BIGINT,
    host_profile_id TEXT,
    host_name TEXT,
    neighbourhood_group TEXT,
    neighbourhood TEXT,
    latitude DECIMAL(10,5),
    longitude DECIMAL(10,5),
    room_type TEXT,
    price INT,
    minimum_nights INT,
    number_of_reviews INT,
    last_review DATE,
    reviews_per_month DECIMAL(5,2),
    calculated_host_listings_count INT,
    availability_365 INT,
    number_of_reviews_ltm INT,
    license TEXT
);
```

---

## Analysis Sections

### 1. Data Overview
- Total listings, hosts, and neighbourhoods
- Price range, average vs. median comparison
- Data quality assessment (null values, missing prices)

### 2. Location Analysis
- Average and median price by neighbourhood group
- Top 10 most expensive and most affordable neighbourhoods
- Minimum listing threshold to ensure statistical reliability

### 3. Room Type Analysis
- Price and market share comparison across room types (Entire home, Private room, Shared room)

### 4. Host Behavior Analysis
- Single-listing hosts vs. multi-listing (commercial) hosts
- Price differences between host categories
- Top hosts by listing count

### 5. Demand Signals
- Relationship between price and number of reviews (booking proxy)
- Availability patterns across price ranges
- Reviews per month as a demand indicator

### 6. Advanced SQL (Window Functions)
- Neighbourhood price rankings within each neighbourhood group
- Individual listing price vs. neighbourhood average comparison

---

## Sample Queries

```sql
-- Price distribution analysis
SELECT
    CASE
        WHEN price <= 100 THEN '$1-100'
        WHEN price <= 200 THEN '$101-200'
        WHEN price <= 500 THEN '$201-500'
        WHEN price <= 1000 THEN '$501-1000'
        ELSE '$1000+'
    END AS price_range,
    COUNT(*) AS total_listings,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM listingsSEA
WHERE price IS NOT NULL AND price > 0
GROUP BY price_range
ORDER BY price_range;
```

```sql
-- Each listing compared to its neighbourhood average
SELECT
    name,
    neighbourhood,
    price,
    ROUND(AVG(price) OVER (PARTITION BY neighbourhood), 2) AS neighbourhood_avg,
    price - ROUND(AVG(price) OVER (PARTITION BY neighbourhood), 2) AS price_vs_avg
FROM listingsSEA
WHERE price IS NOT NULL AND price > 0
LIMIT 20;
```

---

## Visualizations

*(Tableau Public dashboard link will be added here)*

---

## How to Reproduce

1. Download the Seattle summary CSV files from [Inside Airbnb](http://insideairbnb.com/)
2. Install PostgreSQL (includes pgAdmin 4)
3. Create a database named `airbnb_seattle` or similar
4. Run the CREATE TABLE script from `sql/create_tables.sql`
5. Import the CSV files via pgAdmin's Import/Export tool (set Header ON, Escape to `"`)
6. Run the analysis queries from `sql/analysis_queries.sql`

---

## Project Structure

```
seattle-airbnb-analysis/
├── README.md
├── data/
│   ├── listings.csv
│   ├── reviews.csv
│   └── neighbourhoods.csv
├── sql/
│   ├── create_tables.sql
│   └── analysis_queries.sql
├── visualizations/
│   └── (Tableau screenshots or exported charts)
└── findings/
    └── summary_report.md
```

---

## Status

🔄 **In Progress** — Currently completing SQL analysis sections and building Tableau dashboard.

---

## Author

**Suum** — Recent Economics graduate from Willamette University. Building a data analyst portfolio combining SQL, R, and Tableau with domain knowledge in economics and market analysis.

- [LinkedIn](#) *(add your link)*
- [GitHub](https://github.com/mangsuum24)
