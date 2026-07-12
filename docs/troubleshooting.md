# Troubleshooting

## Lambda timeout

Increase timeout in Terraform.

---

## Glue job failed

Check:

- CloudWatch Logs
- IAM permissions
- S3 paths

---

## Athena table empty

Verify:

- Glue crawler
- Glue Catalog
- S3 partitions

---

## Step Functions failed

Check execution history.

---

## Terraform apply failed

Run

```bash
terraform plan
```

Review IAM permissions.

---

## GitHub Actions failed

Check

- AWS credentials
- Terraform version
- Backend configuration

---

## SNS email not received

Confirm email subscription.