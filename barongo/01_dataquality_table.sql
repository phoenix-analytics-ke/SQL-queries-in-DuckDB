--Sample Data Quality table 
CREATE OR REPLACE TABLE dataquality AS
SELECT 
    CURRENT_DATE AS run_date,
    'YELLOW' AS dataset,
    (SELECT COUNT(*) FROM yellow_data) AS total_rows,
    (SELECT COUNT(*) FROM yellow_data WHERE fare_amount <= 0 OR trip_distance <= 0) AS invalid_rows,
    (SELECT COUNT(*) FROM yellow_data WHERE tpep_dropoff_datetime < tpep_pickup_datetime) AS bad_timestamps
UNION ALL
SELECT 
    CURRENT_DATE AS run_date,
    'GREEN' AS dataset,
    (SELECT COUNT(*) FROM green_data),
    (SELECT COUNT(*) FROM green_data WHERE fare_amount <= 0 OR trip_distance <= 0),
    (SELECT COUNT(*) FROM green_data WHERE lpep_dropoff_datetime < lpep_pickup_datetime);