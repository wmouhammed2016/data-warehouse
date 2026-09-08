USE master;
GO

-- Drops the entire ecommerce_dw database -- staging, bronze, silver, gold
-- schemas, every table, every view -- in one shot, so the pipeline in
-- ecommerce_pipeline.sql can be rerun from a clean slate.
-- Safe to run whether or not the database currently exists.

IF DB_ID('ecommerce_dw') IS NOT NULL
BEGIN
    -- Force out any other open connections (SSMS, a leftover sqlcmd
    -- session, etc.) so the DROP doesn't fail with "database in use".
    ALTER DATABASE ecommerce_dw SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ecommerce_dw;
END;
GO