# Project 1 – Zero-Trust Cloud Bank Network (AWS)

This Terraform project builds a modular VPC with:

- Multi-AZ VPC (`10.0.0.0/16`)
- Public, private app, private DB, and logging subnets
- Centralized VPC Flow Logs to encrypted S3
- Security group skeleton for Zero-Trust policies

Region: **us-east-1**  
IAM user: **netsec-labs** (programmatic only)

Run:

```bash
terraform init
terraform plan
terraform apply
