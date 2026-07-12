# Solution Architecture

## Overview

The AWS Serverless Data Platform is an end-to-end serverless ETL solution that ingests YouTube Trending data, transforms it using a Medallion Architecture, validates data quality, and produces analytics-ready datasets.

---

## High-Level Architecture

```text
YouTube Data API
        │
        ▼
AWS Lambda (Ingestion)
        │
        ▼
Bronze Layer (Amazon S3)
        │
        ▼
AWS Step Functions
        │
        ├──────────────┐
        ▼              ▼
AWS Glue        JSON Reference Lambda
        │              │
        └──────┬───────┘
               ▼
Silver Layer
               │
               ▼
Data Quality Lambda
               │
        Pass / Fail
               │
       ┌───────┴────────┐
       ▼                ▼
Gold Layer          SNS Alert
       │
       ▼
Glue Catalog
       │
       ▼
Amazon Athena
```

---

## AWS Services

| Service | Purpose |
|----------|---------|
| Lambda | Data ingestion and reference data processing |
| Glue | PySpark ETL |
| Step Functions | Workflow orchestration |
| S3 | Data Lake |
| SNS | Notifications |
| EventBridge | Scheduling |
| Athena | SQL Analytics |
| Glue Catalog | Metadata |
| CloudWatch | Monitoring |

---

## Medallion Architecture

### Bronze

Raw immutable data.

### Silver

Cleaned and validated data.

### Gold

Business analytics datasets.

---

## Design Principles

- Serverless
- Event-driven
- Fault tolerant
- Infrastructure as Code
- Cost optimized
- Modular