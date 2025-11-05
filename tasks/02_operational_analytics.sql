-- Trip Summaries yellow taxi
CREATE OR REPLACE TABLE trip_summaries_yellow AS
WITH base AS (
  SELECT 
    y.vendorid,
    y.tpep_pickup_datetime,
    y.tpep_dropoff_datetime,
    y.trip_distance,
    ROUND(DATEDIFF('minute', y.tpep_pickup_datetime, y.tpep_dropoff_datetime), 2) AS trip_duration_minutes,
    y.fare_amount,
    y.total_amount,
    z1.borough AS pickup_borough,
    z2.borough AS dropoff_borough,
    year,
  FROM yellow_data AS y
  LEFT JOIN taxi_zone_lookup AS z1 ON y.pulocationid = z1.locationid
  LEFT JOIN taxi_zone_lookup AS z2 ON y.dolocationid = z2.locationid
  WHERE y.total_amount > 0 AND y.total_amount IS NOT NULL 
        AND y.trip_distance > 0 AND y.trip_distance IS NOT NULL
        AND y.fare_amount > 0 AND y.fare_amount IS NOT NULL
        AND y.tpep_dropoff_datetime > y.tpep_pickup_datetime 
        AND year < 2025 AND year >= 2015
), 
metrics AS (
  SELECT 
    *,
    trip_distance / NULLIF(trip_duration_minutes / 60, 0) AS avg_speed_mph,
    fare_amount / NULLIF(trip_distance, 0) AS fare_per_mile
  FROM base
)
SELECT 
  vendorid,
  pickup_borough,
  dropoff_borough,
  year,
  EXTRACT(MONTH FROM tpep_pickup_datetime) AS month_num,
  STRFTIME('%B', tpep_pickup_datetime) AS month_name,
  COUNT(*) AS total_trips,
  ROUND(AVG(trip_distance),2) AS avg_distance,
  ROUND(AVG(fare_amount),2) AS avg_fare,
  ROUND(AVG(fare_per_mile),2) AS avg_fare_per_mile,
  ROUND(AVG(avg_speed_mph),2) AS avg_speed,
  ROUND(AVG(trip_duration_minutes),2) AS avg_tripduration_minutes
FROM metrics
GROUP BY 1, 2, 3, 4, 5, 6
ORDER BY year, pickup_borough;

-- Trip Summaries green taxi
CREATE OR REPLACE TABLE trip_summaries_green AS
WITH base AS (
  SELECT 
    g.vendorid,
    g.lpep_pickup_datetime,
    g.lpep_dropoff_datetime,
    g.trip_distance,
    ROUND(DATEDIFF('minute', g.lpep_pickup_datetime, g.lpep_dropoff_datetime), 2) AS trip_duration_minutes,
    g.fare_amount,
    g.total_amount,
    z1.borough AS pickup_borough,
    z2.borough AS dropoff_borough,
    year
  FROM green_data AS g
  LEFT JOIN taxi_zone_lookup AS z1 ON g.pulocationid = z1.locationid
  LEFT JOIN taxi_zone_lookup AS z2 ON g.dolocationid = z2.locationid
  WHERE COALESCE(g.total_amount, 0) > 0
    AND COALESCE(g.trip_distance, 0) > 0
    AND COALESCE(g.fare_amount, 0) > 0
    AND g.lpep_dropoff_datetime > g.lpep_pickup_datetime 
    AND g.year BETWEEN 2015 AND 2025
), 
deduplicate AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
        PARTITION BY vendorid,lpep_pickup_datetime,lpep_dropoff_datetime
        ORDER BY total_amount DESC   -- keep the most valuable trip version
    ) AS rn
  FROM base
),
metrics AS (
  SELECT 
    *,
    trip_distance / NULLIF(trip_duration_minutes / 60, 0) AS avg_speed_mph,
    fare_amount / NULLIF(trip_distance, 0) AS fare_per_mile
  FROM deduplicate
  WHERE rn = 1
)
SELECT 
  vendorid,
  pickup_borough,
  dropoff_borough,
  year,
  EXTRACT(MONTH FROM lpep_pickup_datetime) AS month_num,
  STRFTIME('%B', lpep_pickup_datetime) AS month_name,
  COUNT(*) AS total_trips,
  ROUND(AVG(trip_distance),2) AS avg_distance,
  ROUND(AVG(fare_amount),2) AS avg_fare,
  ROUND(AVG(fare_per_mile),2) AS avg_fare_per_mile,
  ROUND(AVG(avg_speed_mph),2) AS avg_speed,
  ROUND(AVG(trip_duration_minutes),2) AS avg_tripduration_minutes
FROM metrics
GROUP BY 1, 2, 3, 4, 5, 6
ORDER BY year, pickup_borough;

-- Hourly Trends Yellow & Green Taxi
CREATE OR REPLACE TABLE hourly_trends AS
SELECT
    'Yellow' AS dataset,
    year,
    CASE 
      WHEN EXTRACT(HOUR FROM tpep_pickup_datetime) BETWEEN 0 AND 11
          THEN LPAD(CAST(EXTRACT(HOUR FROM tpep_pickup_datetime) AS VARCHAR), 2, '0') || ':' || '00' ||' ' || 'AM'
      WHEN EXTRACT(HOUR FROM tpep_pickup_datetime) BETWEEN 12 AND 23
          THEN LPAD(CAST(EXTRACT(HOUR FROM tpep_pickup_datetime) AS VARCHAR), 2, '0') || ':' || '00' ||' ' || 'PM'  
      ELSE 'Invalid' END AS pickup_hour,
    COUNT(*) AS total_trips
FROM yellow_data
WHERE year < 2025 AND year >= 2015
GROUP BY year, pickup_hour
UNION ALL
SELECT 
    'Green' AS dataset,
    year,
   CASE 
      WHEN EXTRACT(HOUR FROM tpep_pickup_datetime) BETWEEN 0 AND 11
          THEN LPAD(CAST(EXTRACT(HOUR FROM tpep_pickup_datetime) AS VARCHAR), 2, '0') || ':' || '00' ||' ' || 'AM'
      WHEN EXTRACT(HOUR FROM tpep_pickup_datetime) BETWEEN 12 AND 23
          THEN LPAD(CAST(EXTRACT(HOUR FROM tpep_pickup_datetime) AS VARCHAR), 2, '0') || ':' || '00' ||' ' || 'PM'  
      ELSE 'Invalid' END AS pickup_hour,
    COUNT(*) AS total_trips
FROM green_data
WHERE year < 2025 AND year >= 2015
GROUP BY year, pickup_hour
ORDER BY year, pickup_hour;



