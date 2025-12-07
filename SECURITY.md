# 🔐 Security Policy

This repository contains **educational cloud-security portfolio projects** simulating financial-grade security architecture using AWS, Terraform, IAM/CIEM, network segmentation, and SOC automation.  
Although these projects do **not run production workloads**, good disclosure practices are still required.

---

## 🛡 Supported Versions

This project evolves with AWS service updates, Terraform versions, and financial security controls (PCI DSS, FFIEC, CSA CCM).  
Active development occurs on the `main` branch.

| Component | Support Policy |
|-----------|----------------|
| Terraform modules | ✔ Always updated to stable releases |
| AWS services | ✔ Updated to currently available GA features |
| Draw.io, CIEM models, Forensic artifacts | ✔ Updated per version change |
| Deprecated AWS/IaC patterns | ❌ Removed without backward support |

> **No backward support for insecure legacy patterns** (e.g., wildcard roles, public S3 buckets, permissive Security Groups).

---

## Reporting a Vulnerability

If you believe you’ve identified a security flaw in:

- Terraform modules (network/security policies)
- IAM/CIEM/RBAC/ABAC mappings
- Logging/SIEM or forensic automation scripts
- Threat models, misconfigurations, or documentation errors

**Please do NOT open a public GitHub issue.**

Instead, submit a **Private Security Advisory** via GitHub **or contact me professionally on LinkedIn**.

### Please include:

- Affected project: **(1–6 portfolio projects)**
- Steps to reproduce (if applicable)
- Service(s) impacted (e.g., IAM, VPC, KMS, Lambda, GuardDuty, WAF, S3)
- Potential Risk: *(data exposure, privilege escalation, identity takeover, lateral movement, forensic bypass, etc.)*

---

## Disclosure Statement

The portfolio:

- does **not** contain customer information
- does **not** include reusable production keys or cloud credentials
- uses **tokenized, anonymized forensic examples**
- follows **responsible disclosure** to maintain realistic cloud-security standards

> Educational Use Only — **not a deployable product.**  
The purpose is to demonstrate secure patterns and **avoid insecure ones.**

---

## 🧱 Acceptable Contributions

| Contribution Type | Accepted? | Notes |
|------------------|-----------|------|
| Fixing insecure IaC/CIEM | ✔ | Reviewed under private advisory |
| Enhancing threat models | ✔ | Especially for financial/PCI/Fraud |
| Expanding forensic playbooks | ✔ | Must map to SOC Tiers & MITRE ATT&CK |
| Adding new AWS services/scripts | ⚠ Review | Must maintain Zero-Trust posture |
| Adding non-secure cloud shortcuts | ❌ | Will be rejected immediately |

---

## Compliance & Best Practices

This repository aligns with:

- **PCI DSS v4.0**
- **FFIEC: Information Security Handbook**
- **CSA CCM + Zero Trust**
- **MITRE ATT&CK (Cloud Matrix)**
- **AWS Well-Architected Security Pillar**

---

### Final Note

*Security is a journey, not a checkbox.*  
If you spot something that can be hardened, improved, or better aligned to enterprise Zero-Trust + Banking Threats, please share responsibly.

**Together, we build safer cloud systems.**

