# Project 1 – Zero-Trust Micro-Segmented Banking Network (AWS)

> Phase 1 of 4 – Cloud Network Security Engineer (Financial Sector Portfolio)  
> Foundation: VPC, Micro-Segmentation, Multi-Region Logging

---

## 1. Objective

Design and deploy a **Zero-Trust micro-segmented network** for a cloud-hosted banking platform using AWS, with:

- Strong East/West isolation (between app, DB, and logging tiers)
- Least-privilege network paths
- Multi-region logging for **forensics and compliance**
- Terraform-based, modular, and repeatable architecture

This project is the **network and observability foundation** for Projects 2–4 (XDR, API security, CIEM & data protection).

---

## 2. Business & Security Outcomes

- Reduce lateral movement risk for ransomware and internal threats
- Provide clear network zones for compliance (PCI DSS, OSFI B-13, FFIEC)
- Make all critical network activity observable and auditable
- Enable future XDR/SOAR and fraud analytics

| Outcome | Description |
|--------|-------------|
| Micro-segmentation | Separate public, app, DB, and logging tiers across AZs |
| Least-privilege paths | Only required paths are opened between tiers |
| Multi-region resilience | Logs stored in a different region from workloads |
| Terraform IaC | Reproducible, version-controlled security architecture |

---

## 3. Regulatory Alignment

| Standard / Guidance | Relevant Requirement | How This Design Helps |
|---------------------|----------------------|------------------------|
| **OSFI B-13 (Canada)** | Technology & cyber-risk management, log retention | Multi-region logging, KMS encryption, VPC isolation |
| **FFIEC / NYDFS (US)** | Network segmentation, forensics | Tiered VPC, flow logs, CloudTrail | 
| **PCI DSS 4.0** | Cardholder data environment isolation | Isolated DB subnets, security groups, no direct internet |
| **SOC 2 / ISO 27001** | Principle of least privilege | Security groups, IAM roles, subnet-level separation |

---

## 4. Architecture Overview (Style B – With Legend)

### 4.1 High-Level Network Architecture

```text
                   ┌──────────────────────────────┐
                   │          Internet            │
                   └──────────────┬───────────────┘
                                  │
                           AWS WAF / Shield
                                  │
                        ┌─────────▼─────────┐
                        │  Public Subnets   │
                        │ (ALB / Bastion)   │
                        └─────────┬─────────┘
                                  │
                     ┌────────────▼────────────┐
                     │     App Subnets         │
                     │ (Core Banking APIs,     │
                     │  Microservices)         │
                     └────────────┬────────────┘
                                  │
                     ┌────────────▼────────────┐
                     │      DB Subnets         │
                     │ (RDS, Ledger, Vault)    │
                     └────────────┬────────────┘
                                  │
                     ┌────────────▼────────────┐
                     │   Logging Subnets       │
                     │ (Flow Logs, Security    │
                     │  Tools, Inspectors)     │
                     └─────────────────────────┘

4.2 Multi-Region Log Topology

Region A – us-east-1 (Prod)        Region C – ca-central-1 (Forensics)
────────────────────────────        ───────────────────────────────────
VPC + Subnets + SGs           →     S3 Forensic Buckets (Object Lock)
VPC Flow Logs                 →     CloudWatch Log Export
CloudTrail Management Events  →     Cross-region replication

Legend
Public Subnets – Internet-facing, strictly limited (ALB, optional bastion)

App Subnets – Business logic / APIs, only reachable via ALB or PrivateLink

DB Subnets – No Internet access, only from app tier SG

Logging Subnets – Security tooling, SIEM collectors, flow logs

Forensic Region – Region dedicated to long-term, immutable log retention

5. Terraform Layout

project-1-zero-trust/
├── main.tf
├── provider.tf
├── variables.tf
├── outputs.tf
├── README.md
└── modules/
    ├── vpc/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── subnets/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── security/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── logging/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf

Key responsibilities:

vpc/ – VPC, IGW, tags

subnets/ – public/app/db/logging subnets (+ route tables)

security/ – base security groups (will be hardened in later phases)

logging/ – VPC Flow Logs → CloudWatch → cross-region S3 (forensics)

6. Threat Model & Mitigations (Phase 1)

| Threat                         | Control in This Project                |
| ------------------------------ | -------------------------------------- |
| Lateral movement between tiers | Micro-segmented subnets and tiered SGs |
| Direct DB exposure             | DB subnets have no IGW / NAT           |
| Undetected network scans       | Flow Logs (ALL) + central log region   |
| Single-region outage           | Logs preserved in separate region      |
