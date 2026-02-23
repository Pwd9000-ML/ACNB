-- Purpose: Perform an idempotent incremental load from a staging table into a Delta target table.
-- Usage: Update catalog/schema/table names and run in Databricks SQL.

USE CATALOG main;
CREATE SCHEMA IF NOT EXISTS analytics;
USE analytics;

-- Target table (Delta) with common customer profile fields.
CREATE TABLE IF NOT EXISTS dim_customer (
  customer_id STRING,
  first_name STRING,
  last_name STRING,
  email STRING,
  status STRING,
  updated_at TIMESTAMP,
  created_at TIMESTAMP
)
USING DELTA
TBLPROPERTIES (
  delta.autoOptimize.optimizeWrite = true,
  delta.autoOptimize.autoCompact = true
);

-- Example staging view/table expected columns:
-- customer_id, first_name, last_name, email, status, updated_at, created_at

MERGE INTO dim_customer AS tgt
USING (
  SELECT
    customer_id,
    first_name,
    last_name,
    email,
    status,
    updated_at,
    created_at
  FROM stg_customer_updates
  QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY updated_at DESC) = 1
) AS src
ON tgt.customer_id = src.customer_id

WHEN MATCHED AND src.updated_at > tgt.updated_at THEN
  UPDATE SET
    tgt.first_name = src.first_name,
    tgt.last_name = src.last_name,
    tgt.email = src.email,
    tgt.status = src.status,
    tgt.updated_at = src.updated_at

WHEN NOT MATCHED THEN
  INSERT (
    customer_id,
    first_name,
    last_name,
    email,
    status,
    updated_at,
    created_at
  )
  VALUES (
    src.customer_id,
    src.first_name,
    src.last_name,
    src.email,
    src.status,
    src.updated_at,
    COALESCE(src.created_at, current_timestamp())
  );

-- Quick post-load validation.
SELECT
  COUNT(*) AS total_customers,
  MAX(updated_at) AS last_update_ts
FROM dim_customer;
