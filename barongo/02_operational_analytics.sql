-- Trip Summaries
CREATE OR REPLACE TABLE trip_summaries AS
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
    year
  FROM yellow_data AS y
  LEFT JOIN taxi_zone_lookup AS z1 ON y.pulocationid = z1.locationid
  LEFT JOIN taxi_zone_lookup AS z2 ON y.dolocationid = z2.locationid
  WHERE total_amount > 0 AND  y.tpep_dropoff_datetime > y.tpep_pickup_datetime AND year < 2025
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
  AVG(trip_distance) AS avg_distance,
  AVG(fare_amount) AS avg_fare,
  AVG(fare_per_mile) AS avg_fare_per_mile,
  AVG(avg_speed_mph) AS avg_speed
FROM metrics
GROUP BY 1, 2, 3, 4, 5, 6
ORDER BY year, pickup_borough;

-- Hourly Trends
CREATE OR REPLACE TABLE hourly_trends AS
SELECT 
    year,
    EXTRACT(HOUR FROM tpep_pickup_datetime) AS pickup_hour,
    COUNT(*) AS total_trips
FROM yellow_data
WHERE year < 2025
GROUP BY year, pickup_hour
ORDER BY year, pickup_hour;

