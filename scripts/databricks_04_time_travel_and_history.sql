-- Purpose: Demonstrate Delta Lake time travel to query past table versions, audit history, and restore data.
-- Usage: Run against the dim_customer table created in databricks_01_incremental_customer_merge.sql.

USE CATALOG main;
USE analytics;

-- 1) Inspect the full change history of the table.
-- Each operation (WRITE, MERGE, OPTIMIZE, VACUUM, etc.) is recorded as a versioned entry.
DESCRIBE HISTORY dim_customer;

-- 2) Query the table as it existed at a specific past version.
-- Useful for auditing what data looked like before a merge or bulk update.
SELECT *
FROM dim_customer VERSION AS OF 0
LIMIT 20;

-- 3) Query the table as it existed at a specific point in time.
-- Replace the timestamp literal with a value from the DESCRIBE HISTORY output.
SELECT *
FROM dim_customer TIMESTAMP AS OF '2025-01-01T00:00:00.000Z'
LIMIT 20;

-- 4) Compare current records against a historical version to identify what changed.
-- Returns rows where email differs between now and version 0 (initial load).
SELECT
  current.customer_id,
  current.email        AS current_email,
  historical.email     AS email_at_v0,
  current.updated_at   AS current_updated_at
FROM dim_customer AS current
JOIN dim_customer VERSION AS OF 0 AS historical
  ON current.customer_id = historical.customer_id
WHERE current.email <> historical.email;

-- 5) Restore the table to a previous version.
-- Use with caution. This rewrites the current table state to match the chosen version.
-- Uncomment and supply the target version number when you need to roll back.
-- RESTORE TABLE dim_customer TO VERSION AS OF 0;

-- 6) Confirm the restore operation is recorded in history.
DESCRIBE HISTORY dim_customer;
