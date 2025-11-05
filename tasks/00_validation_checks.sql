-- Check for missing values in critical fields
SELECT 
    COUNT(*) AS missing_fares
FROM yellow_data
WHERE fare_amount IS NULL OR total_amount IS NULL;

SELECT 
    COUNT(*) AS missing_fares
FROM green_data
WHERE fare_amount IS NULL OR total_amount IS NULL;

SELECT 
    COUNT(*) AS missing_trips
FROM yellow_data
WHERE tpep_pickup_datetime IS NULL OR tpep_dropoff_datetime IS NULL
    OR pulocationid IS NULL OR dolocationid IS NULL
    OR trip_distance IS NULL;

SELECT 
    COUNT(*) AS missing_trips
FROM green_data
WHERE lpep_pickup_datetime IS NULL OR lpep_dropoff_datetime IS NULL
    OR pulocationid IS NULL OR dolocationid IS NULL
    OR trip_distance IS NULL;

SELECT 
    COUNT(*) AS missing_passenger_counts
FROM yellow_data
WHERE passenger_count IS NULL;

SELECT 
    COUNT(*) AS missing_passenger_counts
FROM green_data
WHERE passenger_count IS NULL;

SELECT COUNT (*) AS missing_surcharges
FROM yellow_data
WHERE extra IS NULL OR mta_tax IS NULL OR tip_amount IS NULL
    OR tolls_amount IS NULL OR improvement_surcharge IS NULL
     OR congestion_surcharge IS NULL;

SELECT COUNT (*) AS missing_surcharges
FROM green_data
WHERE extra IS NULL OR mta_tax IS NULL OR tip_amount IS NULL
    OR tolls_amount IS NULL OR improvement_surcharge IS NULL 
    OR congestion_surcharge IS NULL;

SELECT 
    COUNT(*) AS missing_vendorids
FROM yellow_data
WHERE vendorid IS NULL;

SELECT 
    COUNT(*) AS missing_vendorids
FROM green_data
WHERE vendorid IS NULL;

SELECT 
    COUNT(*) AS missing_ratecodeids
FROM yellow_data
WHERE ratecodeid IS NULL;

SELECT 
    COUNT(*) AS missing_ratecodeids
FROM green_data
WHERE ratecodeid IS NULL;

-- Negative or zero fares/distances/surcharges
SELECT 
    COUNT(*) AS invalid_records
FROM yellow_data
WHERE fare_amount <= 0 OR trip_distance <= 0
    OR extra < 0 OR mta_tax < 0 OR tip_amount < 0
    OR tolls_amount < 0 OR improvement_surcharge < 0
    OR total_amount <=0 OR congestion_surcharge < 0;

SELECT 
    COUNT(*) AS invalid_records
FROM green_data
WHERE fare_amount <= 0 OR trip_distance <= 0
    OR extra < 0 OR mta_tax < 0 OR tip_amount < 0
    OR tolls_amount < 0 OR improvement_surcharge < 0
    OR total_amount <=0 OR congestion_surcharge < 0;

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

--Irrelevant data

SELECT 
    COUNT(*) AS irrelevant
FROM yellow_data
WHERE year < 2015 OR year > 2025;

SELECT 
    COUNT(*) AS irrelevant
FROM green_data
WHERE year < 2015 OR year > 2025;