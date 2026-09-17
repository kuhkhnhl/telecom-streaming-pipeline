-- Bronze: telecom.customers is loaded from the CSV with:
-- bq load --autodetect --source_format=CSV telecom.customers ./telco_churn.csv

-- Silver: fix TotalCharges type and rename the ID
CREATE OR REPLACE VIEW telecom.silver_customers AS
SELECT
  customerID AS customer_id,
  * EXCEPT(customerID, TotalCharges),
  SAFE_CAST(TotalCharges AS FLOAT64) AS total_charges
FROM telecom.customers;

-- Gold: train a boosted tree (XGBoost) churn classifier
CREATE OR REPLACE MODEL telecom.churn_model
OPTIONS(
  model_type = 'BOOSTED_TREE_CLASSIFIER',
  input_label_cols = ['Churn'],
  enable_global_explain = TRUE
) AS
SELECT * EXCEPT(customer_id)
FROM telecom.silver_customers;

-- Evaluate the model
SELECT * FROM ML.EVALUATE(MODEL telecom.churn_model);

-- Top churn drivers
SELECT feature, ROUND(attribution, 4) AS importance
FROM ML.GLOBAL_EXPLAIN(MODEL telecom.churn_model)
ORDER BY attribution DESC
LIMIT 10;

-- Gold: churn probability for every customer
-- Churn was auto-detected as BOOL, so the label is TRUE, not 'Yes'
CREATE OR REPLACE TABLE telecom.gold_churn_risk AS
SELECT
  customer_id,
  Contract,
  tenure,
  MonthlyCharges,
  predicted_Churn,
  ROUND((SELECT prob FROM UNNEST(predicted_Churn_probs) WHERE label = TRUE), 3) AS churn_probability
FROM ML.PREDICT(
  MODEL telecom.churn_model,
  (SELECT * FROM telecom.silver_customers)
);

-- Highest-risk customers
SELECT *
FROM telecom.gold_churn_risk
ORDER BY churn_probability DESC
LIMIT 10;
