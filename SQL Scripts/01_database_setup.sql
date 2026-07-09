
-- ===================================================================================================
-- ENVIRONMENT INITIALIZATION: DATA WAREHOUSE PROVISIONING
-- Objective: Tear down conflicting database instances and establish a clean execution environment.
-- ===================================================================================================

USE master;
GO

-- Terminating existing connections and removing older project instances to ensure state consistency
DROP DATABASE IF EXISTS ECommerce;
GO

-- Provisioning the dedicated enterprise E-Commerce data warehouse container
CREATE DATABASE ECommerce;
GO

-- Shifting context to the newly created analytical database engine
USE ECommerce;
GO


-- ===================================================================================================
-- MEDALLION ARCHITECTURE LAYER PROVISIONING
-- Objective: Establish isolated logical schemas to decouple raw ingestion from structured transformations.
-- ===================================================================================================

-- 1. BRONZE LAYER: Raw Data Ingestion Zone (Immutable landing area for external source CSV files)
CREATE SCHEMA Bronze;
GO

-- 2. SILVER LAYER: Data Cleansing & Conformance Zone (Validated, deduplicated, and unified data)
CREATE SCHEMA Silver;
GO

-- 3. GOLD LAYER: Business Analytics & Reporting Zone (Aggregated views optimized for Power BI/BI tools)
CREATE SCHEMA Gold;
GO