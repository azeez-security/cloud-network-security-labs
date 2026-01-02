## Week 4 – Forensics & FinOps Evidence

- S3 Forensic Vault (ca-central-1)
- KMS CMK with SOC/Audit/Break-glass separation
- TLS + SSE-KMS enforced
- Delete protection via policy + Object Lock (WORM)
- FinOps budgets with multi-threshold SNS alerts
- Evidence exported via terraform show

This design prevents:
- Rogue admin deletion
- Unencrypted uploads
- Cross-region evidence tampering
