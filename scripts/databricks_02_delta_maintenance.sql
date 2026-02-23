-- Purpose: Keep Delta tables fast and storage-efficient using OPTIMIZE and VACUUM.
-- Usage: Run during low-traffic windows, and tune table names/retention as needed.

USE CATALOG main;
USE analytics;

-- Optional: Ensure Change Data Feed is enabled when downstream incremental consumers need it.
ALTER TABLE dim_customer SET TBLPROPERTIES (
  delta.enableChangeDataFeed = true
);

-- Compact small files and improve data skipping for frequent filter columns.
OPTIMIZE dim_customer
ZORDER BY (customer_id, status, updated_at);

-- Refresh table statistics to improve query planning.
ANALYZE TABLE dim_customer COMPUTE STATISTICS;
ANALYZE TABLE dim_customer COMPUTE STATISTICS FOR ALL COLUMNS;

-- Housekeeping: remove obsolete files.
-- Default retention is 7 days. Keep this unless compliance policies require a different value.
VACUUM dim_customer RETAIN 168 HOURS;

-- Operational visibility query.
DESCRIBE DETAIL dim_customer;
