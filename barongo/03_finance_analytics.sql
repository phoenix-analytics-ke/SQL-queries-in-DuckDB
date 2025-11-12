--Monthly Revenue Summary
CREATE OR REPLACE TABLE fin_monthly_revenue AS
SELECT
    year,
    EXTRACT(MONTH FROM tpep_pickup_datetime) AS month_num,
    STRFTIME('%B', tpep_pickup_datetime) AS month_name,
    ROUND(SUM(fare_amount), 2) AS total_fare,
    ROUND(SUM(extra + mta_tax + improvement_surcharge), 2) AS total_surcharges,
    ROUND(SUM(tip_amount), 2) AS total_tips,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM yellow_data
WHERE fare_amount > 0 AND total_amount > 0 AND year < 2025
GROUP BY year, month_num, month_name
ORDER BY year, month_num;

--Payment Type Distribution
CREATE OR REPLACE TABLE fin_payment_type_distribution AS
SELECT
    CASE payment_type
        WHEN 1 THEN 'Credit Card'
        WHEN 2 THEN 'Cash'
        WHEN 3 THEN 'No Charge'
        WHEN 4 THEN 'Dispute'
        WHEN 5 THEN 'Unknown'
        ELSE 'Other'
    END AS payment_method,
    year,
    COUNT(*) AS num_trips,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM yellow_data
WHERE total_amount > 0 AND year < 2025
GROUP BY payment_method, year
ORDER BY year, total_revenue DESC;

--Zonal Profitability Metrics
CREATE OR REPLACE TABLE fin_borough_profitability AS
SELECT
    z1.borough AS pickup_borough,
    year,
    ROUND(SUM(y.total_amount), 2) AS total_revenue,
    ROUND(SUM(y.fare_amount), 2) AS total_fares,
    ROUND(SUM(y.tip_amount), 2) AS total_tips,
    ROUND(AVG(y.total_amount / NULLIF(y.trip_distance, 0)), 2) AS avg_revenue_per_mile,
    ROUND(AVG(y.tip_amount) , 3) AS avg_tip
FROM yellow_data y
LEFT JOIN taxi_zone_lookup z1 ON y.pulocationid = z1.locationid
WHERE y.total_amount > 0 AND y.trip_distance > 0 AND year < 2025
GROUP BY pickup_borough, year
ORDER BY year, total_revenue DESC;

--Year-over-Year (yoy) Revenue Growth
CREATE OR REPLACE TABLE fin_yoy_revenue_growth AS
WITH yearly_totals AS (
    SELECT
        year,
        ROUND(SUM(total_amount), 2) AS annual_revenue
    FROM yellow_data
    WHERE year < 2025
    GROUP BY year
),
growth_calc AS (
    SELECT
        year,
        annual_revenue,
        LAG(annual_revenue) OVER (ORDER BY year) AS prev_year_revenue,
        ROUND(((annual_revenue - LAG(annual_revenue) OVER (ORDER BY year)) / 
               NULLIF(LAG(annual_revenue) OVER (ORDER BY year), 0)) * 100, 2) AS yoy_growth_pct
    FROM yearly_totals
)
SELECT * FROM growth_calc;

--Borough Revenue Flow
CREATE OR REPLACE TABLE fin_borough_do_pu_flow AS
SELECT
    z1.borough AS pickup_borough,
    z2.borough AS dropoff_borough,
    year,
    ROUND(SUM(y.total_amount), 2) AS total_revenue,
    COUNT(*) AS total_trips,
    ROUND(SUM(y.total_amount) / NULLIF(COUNT(*), 0), 2) AS avg_revenue_per_trip,
    ROUND(SUM(y.trip_distance), 2) AS total_distance,
    ROUND(AVG(y.trip_distance), 2) AS avg_distance
FROM yellow_data y
LEFT JOIN taxi_zone_lookup z1 ON y.pulocationid = z1.locationid
LEFT JOIN taxi_zone_lookup z2 ON y.dolocationid = z2.locationid
WHERE y.total_amount > 0 AND y.trip_distance > 0 AND year < 2025
GROUP BY pickup_borough, dropoff_borough, year
ORDER BY year, total_revenue DESC;
