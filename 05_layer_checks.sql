-- Data quality check: Silver has no duplicates
SELECT
  (SELECT COUNT(*) FROM telecom.cdr_raw) AS bronze_rows,
  COUNT(*) AS silver_rows,
  COUNT(DISTINCT call_id) AS unique_calls
FROM telecom.silver_cdr;

-- Bronze vs Silver vs Gold comparison
WITH
bronze AS (SELECT COUNT(*) AS row_count, COUNT(*) AS calls FROM telecom.cdr_raw),
silver AS (SELECT COUNT(*) AS row_count, COUNT(*) AS calls FROM telecom.silver_cdr),
gold_minute AS (SELECT COUNT(*) AS row_count, SUM(calls) AS calls FROM telecom.calls_per_minute),
gold_signal AS (SELECT COUNT(*) AS row_count, SUM(calls) AS calls FROM telecom.signal_vs_drops),
gold_tower AS (SELECT COUNT(*) AS row_count, SUM(calls) AS calls FROM telecom.tower_health)
SELECT 1 AS step, 'Bronze' AS layer, 'cdr_raw' AS object,
  'One row per raw message' AS grain, row_count, calls FROM bronze
UNION ALL
SELECT 2, 'Silver', 'silver_cdr', 'One row per unique call', row_count, calls FROM silver
UNION ALL
SELECT 3, 'Gold', 'calls_per_minute', 'One row per minute', row_count, calls FROM gold_minute
UNION ALL
SELECT 4, 'Gold', 'signal_vs_drops', 'One row per signal band', row_count, calls FROM gold_signal
UNION ALL
SELECT 5, 'Gold', 'tower_health', 'One row per tower, last 15 min', row_count, calls FROM gold_tower
ORDER BY step;

-- Final project numbers
SELECT
  (SELECT COUNT(*) FROM telecom.cdr_raw) AS bronze_rows,
  (SELECT COUNT(*) FROM telecom.silver_cdr) AS silver_rows,
  (SELECT COUNT(DISTINCT tower_id) FROM telecom.silver_cdr) AS towers,
  (SELECT MIN(event_time) FROM telecom.silver_cdr) AS first_event_utc,
  (SELECT MAX(event_time) FROM telecom.silver_cdr) AS last_event_utc,
  (SELECT COUNT(*) FROM telecom.silver_customers) AS customers,
  (SELECT COUNTIF(churn_probability > 0.5) FROM telecom.gold_churn_risk) AS high_risk_customers;
