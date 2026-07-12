# Terraform Modules

## Folder Structure

```text
terraform/

bootstrap/

eventbridge/

glue/

iam/

lambda/

s3/

sns/

step_functions/

variables/
```

---

## bootstrap

Creates backend infrastructure.

---

## s3

Creates

- Bronze bucket
- Silver bucket
- Gold bucket
- Scripts bucket

---

## lambda

Deploys

- YouTube ingestion
- JSON to Parquet
- Data Quality

---

## glue

Creates

Glue Jobs

Uploads PySpark scripts

---

## iam

IAM roles

IAM policies

---

## step_functions

Creates the orchestration workflow.

---

## sns

Creates notifications.

---

## eventbridge

Creates scheduled triggers.

---

## variables

Stores common Terraform variables.