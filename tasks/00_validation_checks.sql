-- Check for missing values in critical fields
SELECT 
    COUNT(*) AS missing_fares
FROM yellow_data
WHERE fare_amount IS NULL OR total_amount IS NULL;

SELECT 
    COUNT(*) AS missing_fares
FROM green_data
WHERE fare_amount IS NULL OR total_amount IS NULL;

-- Negative or zero fares/distances
SELECT 
    COUNT(*) AS invalid_records
FROM yellow_data
WHERE fare_amount <= 0 OR trip_distance <= 0;

SELECT 
    COUNT(*) AS invalid_records
FROM green_data
WHERE fare_amount <= 0 OR trip_distance <= 0;

-- Logical timestamp order
SELECT 
    COUNT(*) AS invalid_timestamps
FROM yellow_data
WHERE tpep_dropoff_datetime < tpep_pickup_datetime;

SELECT 
    COUNT(*) AS invalid_timestamps
FROM green_data
WHERE lpep_dropoff_datetime < lpep_pickup_datetime;

-- Out-of-range duration (e.g. > 8 hours)
SELECT 
    COUNT(*) AS unrealistic_durations
FROM yellow_data
WHERE (tpep_dropoff_datetime - tpep_pickup_datetime) > INTERVAL '8' HOUR;

SELECT 
    COUNT(*) AS unrealistic_durations
FROM green_data
WHERE (lpep_dropoff_datetime - lpep_pickup_datetime) > INTERVAL '8' HOUR;

-- Duplicate detection
SELECT vendorid, tpep_pickup_datetime, tpep_dropoff_datetime, COUNT(*) AS dupes
FROM yellow_data
GROUP BY 1,2,3
HAVING COUNT(*) > 1;

SELECT vendorid, lpep_pickup_datetime, lpep_dropoff_datetime, COUNT(*) AS dupes
FROM green_data
GROUP BY 1,2,3
HAVING COUNT(*) > 1;