# Architecture Decision Record (ADR)

This document outlines the key architectural and design decisions made while building the **AWS Serverless Data Platform** and the reasoning behind each choice.

---

# 1. Why Serverless Architecture?

## Decision

Build the platform using AWS managed serverless services instead of provisioning EC2 instances.

## Services Used

* AWS Lambda
* AWS Glue
* AWS Step Functions
* Amazon EventBridge
* Amazon SNS
* Amazon Athena

## Why?

* No infrastructure management
* Automatic scaling
* Pay only for usage
* Reduced operational overhead
* Suitable for scheduled ETL workloads

---

# 2. Why Terraform?

## Decision

Provision all AWS resources using Terraform.

## Why?

* Infrastructure as Code (IaC)
* Version controlled infrastructure
* Repeatable deployments
* Easy disaster recovery
* Easier collaboration

Instead of manually creating AWS resources through the console, the entire infrastructure can be recreated from code.

---

# 3. Why GitHub Actions?

## Decision

Automate infrastructure deployment using GitHub Actions.

## Why?

* Continuous Integration
* Continuous Deployment
* Automatic Terraform validation
* Consistent deployments
* Eliminates manual deployment steps

---

# 4. Why Medallion Architecture?

## Decision

Organize data into Bronze, Silver, and Gold layers.

## Why?

Separating raw, cleansed, and business-ready datasets improves maintainability and data quality.

### Bronze

* Raw immutable data
* Original API response
* Supports reprocessing

### Silver

* Cleansed data
* Schema enforcement
* Type conversions
* Deduplication

### Gold

* Business-ready datasets
* Aggregated metrics
* Analytics optimized

---

# 5. Why Amazon S3 as the Data Lake?

## Decision

Store all datasets in Amazon S3.

## Why?

* Durable
* Highly scalable
* Low storage cost
* Native integration with Glue and Athena
* Supports partitioned datasets

---

# 6. Why AWS Glue?

## Decision

Perform large-scale transformations using AWS Glue and PySpark.

## Why?

* Native Spark support
* Serverless execution
* Handles large datasets efficiently
* Integrates with Glue Catalog
* Suitable for distributed ETL

---

# 7. Why AWS Lambda?

## Decision

Use Lambda for lightweight processing tasks.

## Responsibilities

* YouTube API ingestion
* JSON reference data transformation
* Data quality validation

## Why?

These workloads are short-running and event-driven, making Lambda an ideal choice.

---

# 8. Why AWS Step Functions?

## Decision

Use Step Functions to orchestrate the pipeline.

## Why?

Compared to chaining Lambda functions manually, Step Functions provides:

* Visual workflow execution
* Retry policies
* Error handling
* Parallel execution
* Workflow monitoring

This simplifies orchestration and improves reliability.

---

# 9. Why EventBridge?

## Decision

Schedule the pipeline using EventBridge.

## Why?

* Fully managed scheduler
* Native AWS integration
* Reliable execution
* No custom cron servers required

---

# 10. Why Athena?

## Decision

Use Athena as the query engine.

## Why?

* Serverless SQL
* No infrastructure management
* Direct querying of S3
* Integration with Glue Catalog
* Cost-effective for analytical workloads

---

# 11. Why Glue Data Catalog?

## Decision

Register datasets in the Glue Catalog.

## Why?

* Centralized metadata
* Schema management
* Athena integration
* Simplifies data discovery

---

# 12. Why Parquet?

## Decision

Store Silver and Gold datasets in Apache Parquet format.

## Why?

Compared to CSV and JSON:

* Smaller storage footprint
* Columnar storage
* Faster analytical queries
* Better compression
* Optimized for Athena and Spark

---

# 13. Why Partition Data?

## Decision

Partition datasets by region (and time where applicable).

## Why?

Partitioning reduces the amount of data scanned during queries, resulting in:

* Faster execution
* Lower Athena query costs
* Better scalability

---

# 14. Why Data Quality Validation?

## Decision

Validate data before publishing Gold datasets.

## Checks Performed

* Row count validation
* Schema validation
* Null percentage validation
* Data freshness validation
* Value range validation

## Why?

Preventing invalid or incomplete data from reaching business users improves trust in analytical outputs.

---

# 15. Why SNS Notifications?

## Decision

Notify pipeline failures through Amazon SNS.

## Why?

Operational visibility is critical in production systems.

Automatic notifications reduce the time required to detect and respond to failures.

---

# 16. Why Use the YouTube Data API?

## Decision

Ingest live data directly from the YouTube Data API instead of relying solely on static datasets.

## Why?

* Demonstrates real-world API integration
* Enables continuous data ingestion
* Keeps analytics up to date
* Better reflects production data engineering workflows

Historical Kaggle datasets can still be used for backfilling and testing, while live data powers ongoing pipeline execution.

---

# 17. Why Keep Historical Data Separate?

## Decision

Store historical datasets separately from live ingestion.

## Why?

Historical data is useful for:

* Initial backfills
* Local development
* Testing transformations

Live ingestion remains independent and continuously updates the platform without relying on static files.

---

# Summary

This project demonstrates several modern cloud data engineering practices:

* Serverless architecture
* Infrastructure as Code
* CI/CD automation
* Distributed ETL using PySpark
* Medallion Architecture
* Automated data quality validation
* Cloud-native orchestration
* Analytics-ready data lake design
* Scalable and maintainable AWS infrastructure