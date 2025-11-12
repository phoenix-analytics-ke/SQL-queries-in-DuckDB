 --Monthly Revenue Summary
 --Gives further insight on the total revenue composition by % contribution of fares,tips and surcharges to overall revenue per month.
CREATE OR REPLACE TABLE fin_monthly_revenue AS
SELECT
     year,
     EXTRACT(MONTH FROM tpep_pickup_datetime) AS month_num,
     STRFTIME('%B', tpep_pickup_datetime) AS month_name,
     ROUND(SUM(fare_amount), 2) AS total_fare,
     ROUND(SUM(extra + mta_tax + improvement_surcharge + COALESCE(congestion_surcharge,0)), 2) AS total_surcharges,
     ROUND(SUM(tip_amount), 2) AS total_tips,
     ROUND(SUM(total_amount), 2) AS total_revenue,
     ROUND(SUM(fare_amount) / NULLIF(SUM(total_amount),0) * 100, 2) AS fare_revenue_pct,
     ROUND(SUM(tip_amount) / NULLIF(SUM(total_amount),0) * 100, 2) AS tips_revenue_pct,
     ROUND(SUM(extra + mta_tax + improvement_surcharge + COALESCE(congestion_surcharge,0)) 
          / NULLIF(SUM(total_amount),0) * 100, 2) AS surcharge_revenue_pct
FROM yellow_data
WHERE
   COALESCE(total_amount, 0) > 0
     AND COALESCE(fare_amount, 0) > 0
     AND COALESCE(extra, 0) >= 0
     AND COALESCE(mta_tax, 0) >= 0
     AND COALESCE(improvement_surcharge, 0) >= 0
   AND year BETWEEN 2015 AND 2025
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
    EXTRACT(MONTH FROM tpep_pickup_datetime) AS month_num,
    STRFTIME('%B', tpep_pickup_datetime) AS month_name,
    COUNT(*) AS num_trips,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM yellow_data
WHERE COALESCE(total_amount, 0) > 0 AND year BETWEEN 2015 AND 2025
GROUP BY 1,2,3,4
ORDER BY year,month_num, total_revenue DESC;

--Zonal Profitability Metrics
CREATE OR REPLACE TABLE fin_borough_profitability AS
SELECT
    z1.borough AS pickup_borough,
    year,
    EXTRACT(MONTH FROM tpep_pickup_datetime) AS month_num,
    STRFTIME('%B', tpep_pickup_datetime) AS month_name,
    ROUND(SUM(y.total_amount), 2) AS total_revenue,
    ROUND(SUM(y.fare_amount), 2) AS total_fares,
    ROUND(SUM(y.tip_amount), 2) AS total_tips,
    ROUND(AVG(y.total_amount / NULLIF(y.trip_distance, 0)), 2) AS avg_revenue_per_mile,
    ROUND(AVG(y.tip_amount) , 3) AS avg_tip
FROM yellow_data y
LEFT JOIN taxi_zone_lookup z1 ON y.pulocationid = z1.locationid
WHERE COALESCE(y.total_amount,0) > 0 
    AND COALESCE(y.trip_distance,0) > 0 
    AND year BETWEEN 2015 AND 2025
GROUP BY pickup_borough, year, month_num , month_name
ORDER BY year,month_num, total_revenue DESC;

--Year-over-Year (yoy) & month-over-month (MoM) Revenue Growth
--A breakdown of the YoY and MoM growth rate to identify buss stability,growth or shrinkage and insight on high vs low season months 
CREATE OR REPLACE TABLE fin_yoy_MoM_revenue_growth AS
WITH monthly_totals AS (
    SELECT
        year,
        EXTRACT(MONTH FROM tpep_pickup_datetime) AS month_num,
        STRFTIME('%B', tpep_pickup_datetime) AS month_name,
        ROUND(SUM(total_amount), 2) AS Total_revenue
    FROM yellow_data
    WHERE year BETWEEN 2015 AND 2025
    GROUP BY year ,month_num, month_name
),
monthly_growth AS (
    SELECT
        year,
        month_num,
        month_name,
        Total_revenue,
        LAG(Total_revenue) OVER (PARTITION BY year ORDER BY month_num) AS prev_month_revenue,
        ROUND(((Total_revenue - LAG(Total_revenue) OVER (PARTITION BY year ORDER BY month_num)) / 
               NULLIF(LAG(Total_revenue) OVER (PARTITION BY year ORDER BY month_num), 0)) * 100, 2) AS mom_growth_pct
   FROM monthly_totals
), annual_totals AS (
    SELECT
        year,
        ROUND(SUM(Total_revenue), 2) AS annual_revenue
    FROM monthly_totals
    GROUP BY year
), annual_growth AS (
    SELECT
        year,
        annual_revenue,
        LAG(annual_revenue) OVER (ORDER BY year) AS prev_year_revenue,
        ROUND(((annual_revenue - LAG(annual_revenue) OVER (ORDER BY year)) / 
               NULLIF(LAG(annual_revenue) OVER (ORDER BY year), 0)) * 100, 2) AS yoy_growth_pct
    FROM annual_totals
)
SELECT 
    m.year,
    m.month_num,
    m.month_name,
    m.Total_revenue,
    m.mom_growth_pct,
    a.annual_revenue,
    a.yoy_growth_pct
FROM monthly_growth m 
JOIN annual_growth a ON m.year = a.year
ORDER BY m.year, m.month_num;

--Borough Revenue Flow
--Identify borough with highest avg revenue per trip,per mile and per minute.
--Goal is to identify high value and low value  service areas.
CREATE OR REPLACE TABLE fin_borough_do_pu_flow AS
WITH trip_data AS (
SELECT
    z1.borough AS pickup_borough,
    z2.borough AS dropoff_borough,
    year,
    ROUND(SUM(DATEDIFF('minute', y.tpep_pickup_datetime, y.tpep_dropoff_datetime)),2) AS total_trip_duration_minutes,
    ROUND(AVG(DATEDIFF('minute', y.tpep_pickup_datetime, y.tpep_dropoff_datetime)),2) AS avg_trip_duration_minutes,
    ROUND(SUM(y.total_amount), 2) AS total_revenue,
    COUNT(*) AS total_trips,
    ROUND(SUM(y.total_amount) / NULLIF(COUNT(*), 0), 2) AS avg_revenue_per_trip,
    ROUND(SUM(y.trip_distance), 2) AS total_distance,
    ROUND(AVG(y.trip_distance), 2) AS avg_distance
FROM yellow_data y
LEFT JOIN taxi_zone_lookup z1 ON y.pulocationid = z1.locationid
LEFT JOIN taxi_zone_lookup z2 ON y.dolocationid = z2.locationid
WHERE COALESCE(y.total_amount,0) > 0 AND COALESCE(y.trip_distance,0) > 0 AND year BETWEEN 2015 AND 2025
GROUP BY 1,2,3
)
SELECT
    pickup_borough,
    dropoff_borough,
    year,
    total_revenue,
    total_trip_duration_minutes,
    avg_trip_duration_minutes,
    total_revenue/ NULLIF(total_trip_duration_minutes,0) AS avg_revenue_per_minute,
    total_trips,
    avg_revenue_per_trip,
    total_distance,
    avg_distance,
    total_revenue/NULLIF(total_distance,0) AS avg_revenue_per_mile
FROM trip_data
ORDER BY 3,4,7,9,12 DESC;

--Vendor Performance Analysis
--Revenue contribution and tips.
CREATE OR REPLACE TABLE fin_vendor_performance AS
SELECT
    vendorid,
    year,
    EXTRACT(MONTH FROM tpep_pickup_datetime) AS month_num,
    STRFTIME('%B', tpep_pickup_datetime) AS month_name,
    COUNT(*) AS num_trips,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_revenue_per_trip,
    ROUND(SUM(tip_amount),2) AS total_tips,
    ROUND(AVG(tip_amount), 2) AS avg_tip_per_trip
FROM yellow_data
WHERE COALESCE(total_amount,0) > 0 AND year BETWEEN 2015 AND 2025
GROUP BY vendorid,year,month_num,month_name
ORDER BY year,month_num,total_revenue DESC;