# Tier-1 Banking CIDR Strategy (Week 1)

**Purpose:** Prevent overlapping ranges across regions/environments for core banking, ATMs, fraud systems, and forensic logging.

### 🔎 Global Strategy
- Each region receives a /16 block
- Each environment receives a /20 carved from its region /16
- No overlapping ranges → enables future multi-region peering + DR

| Region       | CIDR        | Environments Example                  |
| ------------ | ----------- | ------------------------------------- |
| us-east-1    | 10.0.0.0/16 | PROD (10.0.0.0/20), DR (10.0.16.0/20) |
| ca-central-1 | 10.1.0.0/16 | Forensics & Immutable Logs            |
| us-west-2    | 10.2.0.0/16 | ATM DR + read replicas                |

---
Tier Breakdown (PROD Example)

| Tier                | Purpose                      | CIDR         |
| ------------------- | ---------------------------- | ------------ |
| Public / Ingress    | ALB, Bastion                 | 10.0.0.0/22  |
| Core Banking Apps   | Accounts, Payments           | 10.0.4.0/22  |
| Fraud & AML         | Analytics, ML                | 10.0.8.0/22  |
| Logging / Forensics | Security Lake, VPC Flow Logs | 10.0.12.0/22 |

---
🔐 Risk Avoidance for Banks

| Risk                           | Impact                      | Our Control                         |
| ------------------------------ | --------------------------- | ----------------------------------- |
| Overlapping CIDR after scaling | Multi-region outage         | Fixed allocation per region upfront |
| Fraud systems mixing with core | Silent privilege escalation | Dedicated fraud CIDR block          |
| Logs stored where apps run     | Tampering risk              | Logging CIDR isolated + immutable   |

CIDR = not “just math” — it’s a compliance & forensic decision in Tier-1 banks.
