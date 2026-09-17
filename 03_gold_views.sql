-- Gold layer: business metrics for the dashboard

-- Drop rate and signal per tower, last 15 minutes
CREATE OR REPLACE VIEW telecom.tower_health AS
SELECT
  tower_id,
  COUNT(*) AS calls,
  ROUND(COUNTIF(status = 'dropped') / COUNT(*) * 100, 2) AS drop_rate_pct,
  ROUND(AVG(signal_dbm), 1) AS avg_signal
FROM telecom.silver_cdr
WHERE event_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 15 MINUTE)
GROUP BY tower_id;

-- Traffic and drops per minute
CREATE OR REPLACE VIEW telecom.calls_per_minute AS
SELECT
  TIMESTAMP_TRUNC(event_time, MINUTE) AS minute,
  COUNT(*) AS calls,
  COUNTIF(status = 'dropped') AS dropped
FROM telecom.silver_cdr
GROUP BY minute;

-- Drop rate for weak vs strong signal
CREATE OR REPLACE VIEW telecom.signal_vs_drops AS
SELECT
  signal_band,
  COUNT(*) AS calls,
  ROUND(COUNTIF(status = 'dropped') / COUNT(*) * 100, 2) AS drop_rate_pct
FROM telecom.silver_cdr
GROUP BY signal_band;
