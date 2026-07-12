# Deployment Guide

## Prerequisites

- AWS CLI
- Terraform >= 1.5
- Python 3.11
- Git

---

## Clone Repository

```bash
git clone https://github.com/<username>/aws-serverless-data-platform.git
```

---

## Configure AWS

```bash
aws configure
```

---

## Initialize Terraform

```bash
terraform init
```

---

## Validate

```bash
terraform validate
```

---

## Plan

```bash
terraform plan
```

---

## Apply

```bash
terraform apply
```

---

## Verify Deployment

Check:

- S3 buckets
- Lambda functions
- Glue Jobs
- Step Functions
- SNS
- EventBridge

---

## Destroy

```bash
terraform destroy
```