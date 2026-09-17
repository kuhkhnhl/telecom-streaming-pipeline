-- Bronze layer: raw call records written by the Pub/Sub BigQuery subscription
CREATE SCHEMA telecom OPTIONS(location = 'US');

CREATE TABLE telecom.cdr_raw (
  call_id STRING,
  caller STRING,
  tower_id STRING,
  duration_sec INT64,
  status STRING,
  signal_dbm INT64,
  event_ts STRING
);
