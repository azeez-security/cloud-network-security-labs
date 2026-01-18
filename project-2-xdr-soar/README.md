## Project 2 — Autonomous XDR + SOAR for Cloud Banking (Ransomware + IAM Abuse)

### What this demonstrates (Tier-1 banking outcomes)
- Event-driven XDR/SOAR pipeline: AWS findings -> EventBridge -> SOAR Dispatcher (Lambda)
- Automated containment patterns (guardrails-first): quarantine / IAM key disable (configurable)
- SOC-grade evidence capture: every incident produces an immutable JSON evidence trail in S3 for audit and post-incident review

### Architecture (high level)
1. GuardDuty + Security Hub generate normalized security findings
2. EventBridge rule matches high-severity / selected finding types
3. SOAR Dispatcher Lambda parses the finding and routes actions:
   - IAM abuse -> disable access keys (optional)
   - Ransomware / EC2 threat -> quarantine and snapshot (optional)
4. Evidence is written to S3 under a date + finding-id prefix, including a summary file for quick review

### Evidence (how to validate)
- CloudWatch Logs: SOAR Dispatcher invocation lifecycle + returned JSON output
- S3 Evidence Bucket: `/project-2-xdr-soar/evidence/YYYY/MM/DD/<finding-id>/_summary.json`

### Terraform
- `project-2-xdr-soar/terraform/` = deployable root
- `project-2-xdr-soar/modules/security/` = modular security controls (SecurityHub, GuardDuty, SOAR Lambda, S3 evidence)
