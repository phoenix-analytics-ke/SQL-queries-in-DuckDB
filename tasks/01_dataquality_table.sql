--Sample Data Quality table 
CREATE OR REPLACE TABLE dataquality AS
SELECT 
    CURRENT_DATE AS run_date,
    'YELLOW' AS dataset,
    (SELECT COUNT(*) FROM yellow_data) AS total_rows,
    (SELECT COUNT(*) FROM yellow_data WHERE fare_amount <= 0 OR trip_distance <= 0 OR extra < 0 OR mta_tax < 0 OR tip_amount < 0 OR tolls_amount < 0 OR improvement_surcharge < 0 OR total_amount <=0 OR congestion_surcharge < 0) AS invalid_rows,
    (SELECT COUNT(*) FROM yellow_data WHERE tpep_dropoff_datetime < tpep_pickup_datetime OR (tpep_dropoff_datetime - tpep_pickup_datetime) > INTERVAL '8' HOUR) AS bad_timestamps,
    (SELECT COUNT(*) FROM yellow_data WHERE passenger_count IS NULL) AS trips_with_missing_passengers,
    (SELECT COUNT(*) FROM yellow_data WHERE extra IS NULL OR mta_tax IS NULL OR tip_amount IS NULL OR tolls_amount IS NULL OR improvement_surcharge IS NULL OR congestion_surcharge IS NULL) AS trips_with_missing_surcharges,
    (SELECT COUNT(*) FROM yellow_data WHERE year < 2015 OR year > 2025) AS invalid_data
UNION ALL
SELECT 
    CURRENT_DATE AS run_date,
    'GREEN' AS dataset,
    (SELECT COUNT(*) FROM green_data) AS total_rows,
    (SELECT COUNT(*) FROM green_data WHERE fare_amount <= 0 OR trip_distance <= 0 OR extra < 0 OR mta_tax < 0 OR tip_amount < 0 OR tolls_amount < 0 OR improvement_surcharge < 0 OR total_amount <=0 OR congestion_surcharge < 0) AS invalid_rows,
    (SELECT COUNT(*) FROM green_data WHERE lpep_dropoff_datetime < lpep_pickup_datetime OR (lpep_dropoff_datetime - lpep_pickup_datetime) > INTERVAL '8' HOUR) AS bad_timestamps,
    (SELECT COUNT(*) FROM green_data WHERE passenger_count IS NULL) AS trips_with_missing_passengers,
    (SELECT COUNT(*) FROM green_data WHERE extra IS NULL OR mta_tax IS NULL OR tip_amount IS NULL OR tolls_amount IS NULL OR improvement_surcharge IS NULL OR congestion_surcharge IS NULL) AS trips_with_missing_surcharges,
    (SELECT COUNT(*) FROM green_data WHERE year < 2015 OR year > 2025) AS invalid_data;