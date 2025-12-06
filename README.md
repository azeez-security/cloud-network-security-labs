# Cloud Network Security Engineer – Financial SOC Portfolio

![Zero Trust](https://img.shields.io/badge/Zero%20Trust-Architecture-blue)
![XDR+SOAR](https://img.shields.io/badge/XDR+SOAR-Automation-red)
![PCI DSS](https://img.shields.io/badge/PCI%20DSS-4.0-success)
![OSFI B13](https://img.shields.io/badge/OSFI-B13%20(Tech%20&%20Cyber)-purple)
![API Security](https://img.shields.io/badge/API%20Security-Fraud%20%26%20Bot%20Defense-orange)
![CIEM](https://img.shields.io/badge/CIEM-Identity%20Governance-yellow)
![Tokenization](https://img.shields.io/badge/Data%20Tokenization-Secure%20Vault-green)

> Zero-Trust Network • Autonomous XDR/SOAR • API Fraud & Bot Defense • CIEM & Data Tokenization  
> Designed as a **bank-grade security program** on AWS with multi-region forensics.

---

## Overview

This repository contains a **full security transformation journey** for a cloud banking platform, implemented as four flagship projects:

| Layer | Project | Purpose |
|-------|---------|---------|
| 🌐 Network | **Project 1: Zero-Trust Micro-Segmentation** | Secure VPC tiers & enforce least privilege between services |
| 🛡 Threat Defense | **Project 2: XDR + SOAR** | Detect & auto-respond to ransomware, API fraud, insider threats |
| 🔐 API Security | **Project 3: Fraud & Bot Defense** | Protect online banking APIs from bots, carding, and abuse |
| 🔑 Identity + Data | **Project 4: CIEM + Tokenization** | Reduce overprivilege & protect financial/PII data via tokens |

All projects are built with Terraform and designed to be **realistic for financial institutions** in Canada and the U.S.

---

## Multi-Region Security Design

To emulate banking best practices, the lab uses multiple AWS regions:

| Region | Purpose |
|--------|---------|
| `us-east-1` | Primary production workloads (VPC, APIs, EC2, DBs) |
| `us-west-2` | Disaster Recovery (cold/standby resources) |
| `ca-central-1` | **Forensic audit vault** for immutable logs (`cloud-soc-forensics-ca`) |

This aligns with regulatory expectations (OSFI B-13, PCI DSS 4.0, FFIEC/NYDFS) for:
- Segregated logging  
- Forensic evidence integrity  
- Business continuity and cyber-resilience  

---

## 📁 Repository Structure

```text
cloud-network-security-labs/
│
├── project-1-zero-trust/
│   └── README.md  # Zero-Trust Micro-Segmented Banking Network
│
├── project-2-xdr-soar/
│   └── README.md  # Autonomous XDR + SOAR Threat Response
│
├── project-3-api-fraud-bot-defense/
│   └── README.md  # API Fraud & Bot Defense for Online Banking
│
└── project-4-ciem-tokenization/
    └── README.md  # CIEM + Tokenization & Financial Data Protection

Each project has its own README explaining objectives, architecture, threat models, and interview talking points.

---
**Tools & Services**

| Category         | AWS Services Used                                                                                    |
| ---------------- | ---------------------------------------------------------------------------------------------------- |
| Network          | VPC, Subnets, Route Tables, Security Groups, Transit Gateway (design)                                |
| Threat Detection | GuardDuty, CloudTrail, VPC Flow Logs, AWS Config, WAF logs                                           |
| SOAR Automation  | EventBridge, Lambda, SNS (alerts), tags & quarantine patterns                                        |
| Logging / SIEM   | CloudWatch Logs, Amazon Security Lake, S3 (`cloud-soc-forensics-ca`), OpenSearch Dashboards (design) |
| Data Protection  | KMS, IAM Access Analyzer, SCP-style guardrails (patterns), tokenization via DynamoDB + Lambda        |

---
**Skills Outcomes (Resume / Interview)**

This portfolio demonstrates:

✔ Zero-Trust design & network micro-segmentation (multi-AZ VPC)

✔ Real-world XDR/SOAR automation & Lambda runbooks

✔ API fraud prevention & bot mitigation (WAF + API Gateway)

✔ CIEM-style IAM controls & data tokenization strategy

✔ Multi-region forensic & compliance logging design

✔ Terraform modular Infrastructure as Code for security programs

Interview-ready narratives are included in each project’s README.

---
**Threat Scenarios Covered**

| Threat Type       | Example Scenario                                    | Mitigation                                                   |
| ----------------- | --------------------------------------------------- | ------------------------------------------------------------ |
| 🔴 Ransomware     | EC2 host scanning and encrypting east-west          | GuardDuty + Flow Logs + Lambda quarantine playbook           |
| 🔵 API Fraud      | Credential stuffing & carding on login/payment APIs | WAF rules, rate limiting, SOAR IP block & token freeze       |
| 🟡 Insider Misuse | IAM user escalating privileges or exfiltrating data | CloudTrail + IAM Analyzer + SOAR deactivation & key rotation |

Forensics are exported to the cloud-soc-forensics-ca S3 bucket in ca-central-1 with stricter controls than production.

---
**Next Enhancements (In This Repo)**
Terraform Security Enhancements (Guardrails)

Planned guardrails include:

SCP-style constraints (patterns) to prevent:

Disabling CloudTrail / GuardDuty / Security Lake

Deleting the forensic S3 bucket or logs

Creating wildcard AdministratorAccess-style roles

Making logging buckets public

KMS key separation:

Forensic logs encrypted with a CMK that app roles cannot decrypt

SOC Dashboard – Security Lake + OpenSearch

Planned SOC visualization:

Ingest CloudTrail, VPC Flow Logs, WAF logs, GuardDuty findings into Security Lake

Use OpenSearch Dashboards (or Athena) to visualize:

Attack timelines

Quarantined resources

Fraud/anomaly IPs

IAM privilege abuse events

---
**Target Roles**

This portfolio is intentionally aligned to:

Cloud Network Security Engineer

Network Security Specialist (Cloud-focused)

Security Engineer (SOC + Cloud)

Cloud Security Analyst (Financial)

XDR/SOAR Security Automation Engineer

Cloud Security Architect (Banking / Fintech)

---
**Author**

Cloud Security & Network Engineering Portfolio
Focused on Banking / Fintech SOC Architecture & Zero-Trust Design.
