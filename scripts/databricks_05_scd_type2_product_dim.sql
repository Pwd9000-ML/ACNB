-- Purpose: Implement a Slowly Changing Dimension Type 2 (SCD2) pattern for a product dimension.
-- Usage: Adapt catalog/schema/table names and run in Databricks SQL after setting up a staging source.

USE CATALOG main;
CREATE SCHEMA IF NOT EXISTS analytics;
USE analytics;

-- SCD2 target table.
-- Each row represents one version of a product record.
-- is_current flags the active row; valid_from/valid_to track the effectivity window.
CREATE TABLE IF NOT EXISTS dim_product (
  product_key     BIGINT GENERATED ALWAYS AS IDENTITY,
  product_id      STRING        NOT NULL,
  product_name    STRING,
  category        STRING,
  unit_price      DECIMAL(12,2),
  supplier_id     STRING,
  is_current      BOOLEAN       NOT NULL,
  valid_from      TIMESTAMP     NOT NULL,
  valid_to        TIMESTAMP
)
USING DELTA
TBLPROPERTIES (
  delta.autoOptimize.optimizeWrite = true,
  delta.autoOptimize.autoCompact   = true
);

-- Expected staging table/view columns:
-- product_id, product_name, category, unit_price, supplier_id, changed_at

-- Step 1: Expire rows in the target that differ from the incoming source.
-- Sets is_current = false and closes valid_to for changed records.
MERGE INTO dim_product AS tgt
USING (
  SELECT
    product_id,
    product_name,
    category,
    unit_price,
    supplier_id,
    changed_at
  FROM stg_product_updates
  QUALIFY ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY changed_at DESC) = 1
) AS src
ON  tgt.product_id  = src.product_id
AND tgt.is_current  = true

WHEN MATCHED AND (
     tgt.product_name  <> src.product_name
  OR tgt.category      <> src.category
  OR tgt.unit_price    <> src.unit_price
  OR tgt.supplier_id   <> src.supplier_id
) THEN
  UPDATE SET
    tgt.is_current = false,
    tgt.valid_to   = src.changed_at;

-- Step 2: Insert new current rows for products that were changed or are brand new.
-- Brand-new products have no existing row; changed products had their row expired in Step 1.
INSERT INTO dim_product (
  product_id,
  product_name,
  category,
  unit_price,
  supplier_id,
  is_current,
  valid_from,
  valid_to
)
SELECT
  src.product_id,
  src.product_name,
  src.category,
  src.unit_price,
  src.supplier_id,
  true                   AS is_current,
  src.changed_at         AS valid_from,
  NULL                   AS valid_to
FROM (
  SELECT
    product_id,
    product_name,
    category,
    unit_price,
    supplier_id,
    changed_at
  FROM stg_product_updates
  QUALIFY ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY changed_at DESC) = 1
) AS src
-- Include rows that are new or were just expired (changed).
WHERE NOT EXISTS (
  SELECT 1
  FROM dim_product AS tgt
  WHERE tgt.product_id = src.product_id
    AND tgt.is_current = true
);

-- Post-load validation: confirm only one current row exists per product.
SELECT
  product_id,
  COUNT(*) AS current_row_count
FROM dim_product
WHERE is_current = true
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Browse the full version history for a sample product.
SELECT
  product_id,
  product_name,
  category,
  unit_price,
  is_current,
  valid_from,
  valid_to
FROM dim_product
WHERE product_id = 'REPLACE_WITH_PRODUCT_ID'
ORDER BY valid_from;
