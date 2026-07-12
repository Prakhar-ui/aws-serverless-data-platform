# Pipeline Flow

## Execution Flow

```text
EventBridge

↓

Step Functions

↓

YouTube API Lambda

↓

Bronze

↓

Parallel Processing

↓

Glue Statistics Job

+

JSON Reference Lambda

↓

Silver

↓

Data Quality

↓

Gold

↓

Athena
```

---

## Step 1

EventBridge triggers Step Functions every six hours.

---

## Step 2

Lambda calls YouTube Data API.

Stores:

- Trending videos
- Category metadata

---

## Step 3

Raw JSON is stored in Bronze S3.

---

## Step 4

Parallel Processing

### Glue

Converts raw statistics into Silver Parquet.

### Lambda

Converts category JSON into Silver Parquet.

---

## Step 5

Data Quality

Checks

- Row count
- Null %
- Schema
- Freshness

---

## Step 6

Gold

Creates

- trending_analytics
- channel_analytics
- category_analytics

---

## Step 7

Athena

Business users query Gold tables.