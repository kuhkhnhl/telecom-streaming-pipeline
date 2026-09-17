-- Silver layer: typed, deduplicated, validated call records
CREATE OR REPLACE VIEW telecom.silver_cdr AS
SELECT
  call_id,
  caller,
  tower_id,
  duration_sec,
  status,
  signal_dbm,
  SAFE_CAST(event_ts AS TIMESTAMP) AS event_time,
  IF(signal_dbm < -100, 'weak', 'strong') AS signal_band
FROM telecom.cdr_raw
WHERE call_id IS NOT NULL
  AND call_id NOT LIKE 'test-%'
  AND SAFE_CAST(event_ts AS TIMESTAMP) IS NOT NULL
  AND status IN ('completed', 'dropped', 'failed')
QUALIFY ROW_NUMBER() OVER (PARTITION BY call_id ORDER BY caller) = 1;
