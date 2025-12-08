## 🔒 Security Pull Request Template
_All changes must align with Zero-Trust, CIEM, encrypted-by-default, and forensics-first principles._

### Summary of Change
> Short description of what this change improves or fixes (security, IaC, auth, logging, tokenization, etc.)

---

### 🛡️ How to Contribute Safely
Before submitting, verify the following:

- **No direct commits to `main`**
- **Terraform changes must be reviewed via PR**
- **IAM or RBAC/ABAC modifications require justification + code comments**
- **Log routing to forensics storage MUST NOT be broken**
- **Encryption at rest (KMS) and in transit preserved for all resources**
- **No bypass of CODEOWNERS reviewers**
- **Bank-style Zero-Trust must stay intact** (least privilege, identity boundary, no wildcard IAM, token-based auth enforced)

---

### Security Impact Checklist (Required)

| Control Area | Status |
|--------------|--------|
| **Threat Model Updated?** (diagrams, assumptions, assets, actors) | ☐ Yes / ☐ N/A |
| **Access Scope Reduced or Justified?** (RBAC/ABAC, IAM roles) | ☐ Yes / ☐ N/A |
| **No Wildcard IAM?** (`"*"` actions flagged) | ☐ Confirmed |
| **Encryption Required?** (KMS keys used + no plaintext secrets) | ☐ Confirmed |
| **Logging Preserved?** (Security Lake + Forensic Vault) | ☐ Confirmed |
| **Sensitive Data Tokenized?** (API, DB, CIEM flows) | ☐ Confirmed |
| **No Public Exposure?** (buckets, APIs, dashboards) | ☐ Confirmed |
| **No Reduced Zero-Trust Controls?** | ☐ Confirmed |
| **Terraform Plan Reviewed?** (attach output if applicable) | ☐ Attached / ☐ N/A |

---

### 📎 Attachments (Required for IaC / Terraform Updates)

Please attach:

- `terraform plan` output (paste or upload as `.txt`)
- Any diagram updates (PNG, PDF, draw.io)
- Any new policies or ABAC rules added

> PRs changing IAM, logging, network boundaries, CIEM, or encryption will **not be reviewed without these.**

---

### GitHub Action Guardrail Acknowledgement

> The repo enforces **Terraform Guardrails**.  
> You acknowledge that this PR **must pass the CI rules**, including:

- `terraform fmt -check`
- `terraform validate`
- 🚫 **Blocking IAM wildcard actions (`"*"`)**
- 🚫 **Blocking unapproved exposure of logs or unencrypted storage**

☑ I acknowledge the guardrail enforcement applies to this PR.

---

### Testing Evidence (Required)

> Provide screenshot/log/test evidence of security behavior (SOAR trigger, KMS key usage, IAM rejection, 403 on unauthorized access, etc.)

---
Insert screenshots / logs / test description here

---

### Reviewer Notes (Leave Blank if Not Reviewer)

> For security reviewers to add final notes.

---

### Code Owners Final Decision  
> (_Do not modify this section_)

- **APPROVED?** ☐ Yes / ☐ No  
- **Reviewer:** `@azeez-security`  
- **Severity Category:** ☐ High ☐ Medium ☐ Low  
- **Notes:** _(optional)_  

---

### Reminder
**Merging without proper review, threat model update, or guardrail compliance is prohibited.**  
All changes are treated as production-grade security changes.

---

### Thank You!
Your contribution strengthens a real SOC-driven, Zero-Trust cloud environment.

---