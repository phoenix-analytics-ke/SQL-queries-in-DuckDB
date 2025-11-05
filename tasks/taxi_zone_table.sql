CREATE TABLE IF NOT EXISTS taxi_zone_lookup AS
SELECT * FROM
read_csv('https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv');