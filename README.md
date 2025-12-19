# Cloud Network Security Engineer – Financial SOC Portfolio

![Zero Trust](https://img.shields.io/badge/Zero%20Trust-Architecture-blue)
![XDR+SOAR](https://img.shields.io/badge/XDR+SOAR-Automation-red)
![PCI DSS](https://img.shields.io/badge/PCI%20DSS-4.0-success)
![OSFI B13](https://img.shields.io/badge/OSFI-B13%20(Tech%20&%20Cyber)-purple)
![API Security](https://img.shields.io/badge/API%20Security-Fraud%20%26%20Bot%20Defense-orange)
![CIEM](https://img.shields.io/badge/CIEM-Identity%20Governance-yellow)
![Tokenization](https://img.shields.io/badge/Data%20Tokenization-Secure%20Vault-green)
![Resilience](https://img.shields.io/badge/BCP%20%26%20DR-Financial--Grade-critical)

> Zero-Trust Network • Autonomous XDR/SOAR • API Fraud Defense • CIEM & Tokenization • BCP & Compliance Guardrails
> Designed as a **Tier-1 bank-grade cloud security program** on AWS.

---

## Overview

This repository contains a full end-to-end cloud security transformation for a digital banking platform, implemented as five flagship projects, each mapped to real Tier-1 bank security responsibilities.

| Layer                     | Project                                      | Purpose                                              |
| ------------------------- | -------------------------------------------- | ---------------------------------------------------- |
| 🌐 Network                | **Project 1: Zero-Trust Micro-Segmentation** | Prevent lateral movement across core banking tiers   |
| 🛡 Threat Defense         | **Project 2: Autonomous XDR + SOAR**         | Detect & auto-contain ransomware, fraud, IAM abuse   |
| 🔐 API Security           | **Project 3: API Fraud & Bot Defense**       | Secure digital banking & ATM APIs                    |
| 🔑 Identity & Data        | **Project 4: CIEM + Tokenization**           | Reduce over-privilege & protect PCI/PII              |
| ♻ Resilience & Compliance | **Project 5: BCP, DR & Policy Guardrails**   | Enforce encryption, DR readiness & FinOps compliance |

All projects are implemented using Terraform, validated with OPA / Conftest, and produce SOC-ready evidence artifacts.

---

## Multi-Region Financial Security Design

To emulate banking best practices, the lab uses multiple AWS regions:

| Region         | Purpose                            |
| -------------- | ---------------------------------- |
| `us-east-1`    | Primary banking workloads          |
| `us-west-2`    | Disaster Recovery (active-passive) |
| `ca-central-1` | **Immutable forensic audit vault** |

Aligned with OSFI B-13, PCI DSS 4.0, FFIEC, ISO 22301 requirements.

---

## 📁 Repository Structure

```text
cloud-network-security-labs/
│
├── project-1-zero-trust/
│   └── README.md
│
├── project-2-xdr-soar/
│   └── README.md
│
├── project-3-api-security/
│   └── README.md
│
├── project-4-ciem-tokenization/
│   └── README.md
│
├── project-5-resilience-compliance/
│   └── README.md
│
└── soc-evidence/
    ├── policy-violations/
    ├── incident-response/
    └── forensics/

Each project has its own README explaining objectives, architecture, threat models, and interview talking points.

---

**Tools & Services**

| Category         | AWS Services Used                                                                                           |
| ---------------- | ----------------------------------------------------------------------------------------------------------- |
| Network          | VPC, Subnets, Route Tables, Security Groups, Transit Gateway (design for zero-trust segmentation)           |
| Threat Detection | GuardDuty, CloudTrail, VPC Flow Logs, AWS Config, WAF logs                                                    |
| SOAR Automation  | EventBridge, Lambda, SNS (alerts), tagging & automated quarantine patterns                                   |
| Logging / SIEM   | CloudWatch Logs, Amazon Security Lake, S3 (`cloud-soc-forensics-ca`), OpenSearch Dashboards (design)        |
| Data Protection  | KMS, IAM Access Analyzer, SCP-style guardrails (patterns), tokenization via DynamoDB + Lambda                |

---

**Threat Scenarios Covered**

| Threat Type       | Example Scenario                                    | Mitigation                                                   |
| ----------------- | --------------------------------------------------- | ------------------------------------------------------------ |
| 🔴 Ransomware     | EC2 host scanning and lateral (east-west) movement | GuardDuty + VPC Flow Logs + Lambda-based quarantine playbook |
| 🔵 API Fraud      | Credential stuffing & carding on login/payment APIs | AWS WAF rules, rate limiting, SOAR IP block & token freeze   |
| 🟡 Insider Misuse | IAM privilege escalation or data exfiltration       | CloudTrail + IAM Access Analyzer + automated key/user disable|

All forensic artifacts are exported to the **`cloud-soc-forensics-ca`** S3 bucket in **`ca-central-1`**, with stricter access controls and encryption than production workloads to support audit and incident response.

---

## Planned Security Enhancements (Roadmap)

The following enhancements represent **deliberately staged controls** aligned with
how Tier-1 financial institutions roll out security governance over time.

### Terraform & Cloud Governance Guardrails
Planned guardrails include policy-as-code patterns to prevent:

- Disabling **CloudTrail, GuardDuty, or Security Lake**
- Deleting or weakening **forensic S3 buckets or logs**
- Creating **wildcard AdministratorAccess IAM roles**
- Making logging or audit buckets publicly accessible

**KMS key separation of duties:**
- Forensic logs encrypted with a dedicated CMK
- Application roles explicitly denied decryption access

### SOC Visibility & Analytics
Planned SOC visualization layer:

- Ingest **CloudTrail, VPC Flow Logs, WAF logs, and GuardDuty findings**
  into **Amazon Security Lake**
- Use **OpenSearch Dashboards or Athena** to visualize:
  - Attack timelines
  - Quarantined resources
  - Fraud and anomaly patterns
  - IAM privilege abuse events

These enhancements are intentionally staged to reflect real-world banking deployment patterns and change-control processes.

---

### 🔐 Security Automation & Governance

This repository enforces **production-grade cloud security governance**
aligned with Tier-1 financial institution practices.

| Control Area | Enforcement Mechanism |
|-------------|----------------------|
| Dependency risk management | Dependabot (patch-only updates) |
| IaC vulnerability detection | GitHub CodeQL |
| Secret leak prevention | GitHub Secret Scanning + Push Protection |
| Responsible vulnerability reporting | Security Policy |
| Controlled disclosure workflow | GitHub Security Advisories |

> All infrastructure changes are treated as **Zero-Trust IaC deployments**  
> and must pass automated security controls and governance review before merge.

---
### Governance Architecture Diagram

```text
Developer change
     |
     v
 GitHub Pull Request
     |
     +--> Security PR Template
     |     (threat model, segmentation impact, logging verification)
     |
     v
 CI Security Pipeline (GitHub Actions)
     |
     |-- terraform fmt / validate
     |-- terraform plan (lab-controlled)
     |-- OPA / policy-as-code enforcement
     v
 GitHub Security Controls
     |
     |-- CodeQL (IaC & code scanning)
     |-- Secret Scanning + Push Protection
     |-- Dependabot (controlled dependency updates)
     v
 Branch Protection + CODEOWNERS
     |
     +--> ❌ Merge blocked on any control failure
     |
     v
 Main branch (approved infrastructure only)
     |
     v
 Terraform Apply → AWS Environment
     |
     |-- Zero-Trust VPC / SG / NACL enforcement
     |-- GuardDuty / CloudTrail / Security Lake
     |-- Immutable forensic S3 buckets (ca-central-1)
     |-- WAF + API Gateway + XDR/SOAR automation

---

### 🔐 OPA Guardrails – Encryption Enforcement

This portfolio treats Terraform plans as **regulated change artifacts**, consistent with Tier-1 banking environments.

- Every pull request executes **OPA (Open Policy Agent)** policies against the Terraform plan.
- Any attempt to create **unencrypted S3 buckets, EBS volumes, RDS instances, or Lambda environment variables** results in a hard failure.
- Policy violations are exported as structured JSON evidence to:
  `soc-evidence/policy-violations/opa-encryption-violations.json`
- Evidence is preserved as a **GitHub Actions artifact** for SOC, audit, and governance review.

This demonstrates how a financial institution can **prevent insecure infrastructure from ever being deployed**, rather than detecting it after the fact.

---

### 📁 SOC Evidence Philosophy

This repository mirrors real SOC and regulatory workflows:

- **Infrastructure changes are evaluated before deployment**
- **Policy violations are captured as immutable evidence**
- **Evidence is reviewable, traceable, and audit-ready**
- **Security controls are enforced automatically, not manually**

Terraform plans are treated as **compliance artifacts**, not developer conveniences.

---

### Skills Demonstrated

✔ Zero-Trust network architecture (SGs, NACLs, tier isolation)  
✔ Lateral movement prevention & environment isolation  
✔ Autonomous XDR / SOAR security automation  
✔ Financial API security & fraud defense  
✔ CIEM, IAM governance & data tokenization  
✔ Multi-region DR, encryption enforcement & forensics  
✔ Policy-as-Code with SOC-ready evidence outputs  

---

### Target Roles

This portfolio is intentionally aligned to:

- Cloud Network Security Engineer  
- Security Engineer (SOC + Cloud)  
- XDR / SOAR Automation Engineer  
- Cloud Security Architect (Banking / FinTech)  

---

**Author**

Cloud Security & Network Engineering Portfolio  
Focused on Banking & FinTech SOC Architecture, Zero-Trust Design, and Preventive Security Controls.
