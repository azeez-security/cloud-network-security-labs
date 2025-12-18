## Week 1 – VPC & Multi-Tier CIDR for a Tier-1 Bank

In Week 1 I designed and deployed the **foundational VPC** for a Tier-1 bank scenario with:

- Core banking tier (accounts, ledger, payments)
- Fraud / AML analytics tier
- Logging / security tooling tier
- Reserved space for ATM edge + DR / additional regions

### CIDR Strategy (Designed for 3+ Regions, 5+ Environments)

I treat **CIDR as a long-term risk & cost decision**, not just a technical detail.

For this lab, I use:

- `10.0.0.0/16` for **Region 1 – Lab/Prod**  
- Within that /16, I conceptually reserve ranges for each major tier:

| Tier / Use        | Example Range       | Notes |
|-------------------|---------------------|-------|
| Core-banking app  | `10.0.10.0/24+`     | Internal APIs, business logic |
| Fraud / AML       | `10.0.20.0/24+`     | Analytics, scoring, AML jobs |
| ATM edge (future) | `10.0.40.0/24+`     | Reserved for ATM / POS ingress |
| Logging / tools   | `10.0.200.0/24+`    | VPC Flow Logs, collectors, SIEM agents |
| Public ingress    | `10.0.0.0/24+`      | ALB/API front door, strictly filtered |

**Current Week-1 implementation:**

- Public subnets (ALB / API ingress):  
  - `10.0.0.0/24` (us-east-1a), `10.0.1.0/24` (us-east-1b)
- Core-banking app subnets:  
  - `10.0.10.0/24` (us-east-1a), `10.0.11.0/24` (us-east-1b)
- Fraud / AML subnets:  
  - `10.0.20.0/24` (us-east-1a), `10.0.21.0/24` (us-east-1b)
- Logging / security tooling subnets:  
  - `10.0.200.0/24` (us-east-1a), `10.0.201.0/24` (us-east-1b)

By reserving clear bands (0.x for ingress, 10.x for core, 20.x for fraud/AML, 200.x for logging), it becomes much easier for future teams to:

- Extend the network to **DR regions** (e.g. `10.1.0.0/16` in another region)
- Add **separate environments** (dev/test/prod) without overlapping CIDRs
- Visually reason about which tier traffic belongs to during an incident.

### DNS & VPC Flow Logs

In this week I also:

- Ensured the VPC has **DNS support + DNS hostnames** enabled so that:
  - EC2 and future ECS/Lambda integrations use names, not IPs.
- Configured **VPC Flow Logs to CloudWatch Logs**, tagged for:
  - `Classification=Forensic`, `Usage=vpc-flow-logs`.

These logs will later be exported to a **forensic bucket in another region** as part of Projects 2 and 5.

### Challenges & Lesson Learned

> **Challenge:** Many Tier-1 banks grow their networks organically. Years later, they discover that overlapping or poorly planned CIDR blocks make VPC peering, multi-region DR, or M&A integration almost impossible without a major re-architecture.

> **Resolution:** In this project I designed CIDR blocks with **room for future regions and DR** from the beginning. The Tier/Range allocations and environment planning are documented in the repo so that:
> - New environments or regions can be added without collisions.
> - Security teams can quickly understand **which tier is which** just by looking at IP ranges.

> **Lesson:** *CIDR design is not just a VPC detail — it is a long-term architectural and financial decision. A good plan avoids expensive downtime and rework later.*

---

## Week 1 – VPC & CIDR Strategy for a Tier-1 Bank

### What Was Built This Week

In Week 1, the focus is on laying down a **clean, scalable VPC foundation** for a Tier-1 bank:

- One **core VPC** with DNS support and DNS hostnames enabled.
- **Multi-AZ design** (e.g., `us-east-1a`, `us-east-1b`) for resilience.
- **Four logical tiers**, mapped to common banking domains:
  - **Public / Edge Tier** – internet-facing entry point for online banking & ATM edge APIs.
  - **Core-Banking App Tier** – internal services for core banking (payments, accounts, credit).
  - **Fraud / AML Analytics Tier** – data & analytics layer that inspects transactions.
  - **Logging / Security Tier** – SOC tooling, collectors, and future SIEM/Security Lake.
- **VPC Flow Logs** enabled to **CloudWatch Logs** using a dedicated IAM role.

This is the “network skeleton” that the remaining projects (XDR/SOAR, API security, CIEM, SOC dashboards) will build on.

---

### CIDR Allocation Strategy

The VPC is sized to support **multiple domains in one region** and to avoid future overlap when more regions and environments are added.

Example strategy used in this lab:

- **VPC CIDR (Region block):** `10.0.0.0/16`
  - Gives 65,536 addresses in this region.
- This `/16` is carved into **/20 blocks** for different domains:

| Purpose / Domain          | CIDR Block     | Notes                                                 |
|---------------------------|----------------|-------------------------------------------------------|
| Public / ATM Edge Tier    | `10.0.0.0/20`  | Internet-facing ALB, bastion, API edge                |
| Core-Banking App Tier     | `10.0.16.0/20` | App services (payments, accounts, credit services)    |
| Fraud / AML / Analytics   | `10.0.32.0/20` | Fraud scoring, AML pipelines, risk analytics          |
| Logging / Security Tools  | `10.0.48.0/20` | Flow logs, security agents, SIEM connectors           |
| **Reserved for future**   | `10.0.64.0/20`+| Future DR, new regions, or new regulatory workloads   |

Each `/20` block is then split across **two Availability Zones** with **1 public + 1 private subnet per AZ** for the tiers we implement in Week 1 (public + core + fraud + logging).

This directly addresses a real Tier-1 problem: **CIDR chaos**. Instead of randomly assigning `/24` subnets that later collide across regions, the plan:

- Reserves a **clean `/16` per region**.
- Reserves **consistent blocks per domain** (core, ATM, fraud, logging).
- Leaves headroom for **DR regions and new regulatory workloads**.

All CIDRs are declared centrally in Terraform variables so that **network governance and security** can review and sign-off.

---

### Flow Logs & Observability

To meet OSFI B-13 / PCI expectations around logging:

- A dedicated **CloudWatch Log Group** is created:  
  `/vpc-flow-logs/<project>-flow-logs`
- A **least-privilege IAM role** allows VPC Flow Logs to:
  - Create log streams.
  - Write log events.
- **Traffic type** is set to `ALL`:
  - Ingress, egress, and rejected connections are captured.
- In later weeks, these logs will be:
  - Routed to a **forensic S3 bucket** in `ca-central-1`.
  - Ingested into **Security Lake / OpenSearch** for SOC dashboards.

```
### Network Architecture Diagram (Tier-1 Bank – Week 1)

```text
                        ┌────────────────────────────┐
                        │          Internet          │
                        └─────────────┬──────────────┘
                                      │
                              AWS WAF / Shield
                                      │
                         ┌────────────▼─────────────┐
                         │ Public Subnets (AZ A/B)  │
                         │  - ALB / API Gateway     │
                         │  - Optional bastion      │
                         └────────────┬─────────────┘
                                      │  HTTPS only
         ┌─────────────────────────────┼──────────────────────────────┐
         │                             │                              │
         ▼                             ▼                              ▼
┌─────────────────────┐     ┌─────────────────────┐        ┌─────────────────────┐
│ Core Banking Apps   │     │ Fraud / AML Tier    │        │ Logging / Forensics │
│ Private App Subnets │     │ Private DB Subnets  │        │ Logging Subnets     │
│  - Online banking   │     │  - Fraud models     │        │  - VPC Flow Logs    │
│  - Payments / APIs  │     │  - AML analytics    │        │  - SIEM collectors  │
└─────────┬───────────┘     └─────────┬───────────┘        └─────────┬───────────┘
          │                           │                              │
          │                           │                              │
          └───────────────┬───────────┴───────────────┬──────────────┘
                          │                           │
                          ▼                           ▼
                ┌───────────────────┐        ┌───────────────────┐
                │ Reserved CIDR for │        │ Forensic Region   │
                │ ATM Edge Tier     │        │ (future: S3/SOC)  │
                │ 10.0.16.0/20      │        │ ca-central-1      │
                └───────────────────┘        └───────────────────┘

---

### Week-1 Lesson Learned

> CIDR design is not just a subnetting exercise; it’s a **risk and cost decision**.

By planning the `/16` and `/20` blocks up front, the bank avoids:

- Peering failures due to overlapping CIDRs between regions.
- Costly **re-architecture** when new digital products (e.g., instant payments, new ATM networks) come online.
- Exposure from mis-segmented workloads (fraud/AML sharing networks with core transactional systems).

This lab shows how to document and enforce a **bank-grade CIDR strategy** in Terraform so future changes stay controlled.

---

## Week 2 – Micro-Segmentation of Core, ATM, Fraud, and Logging Tiers

In Week 2, I moved from “CIDR planning” to **enforced micro-segmentation**:

- Each private tier now has its own **route table**:
  - `app-rt` for core-banking app subnets
  - `db-rt` for core DB / fraud-AML subnets
  - `logging-rt` for logging & security tools
- Only the **public / ATM edge** route table has a `0.0.0.0/0` route to the IGW.
- I introduced a **bank-grade set of Security Groups**:

| SG                        | Purpose                                                       |
|---------------------------|---------------------------------------------------------------|
| `sg-alb-edge`            | Internet-facing ALB / ATM edge (443 only from Internet)       |
| `sg-core-app`            | Core-banking app tier (443 only from `sg-alb-edge`)           |
| `sg-core-db`             | Core DB – only 5432 allowed from `sg-core-app`                |
| `sg-fraud-analytics`     | Fraud/AML analytics – can read logs/events, no DB access      |
| `sg-logging-tools`       | Logging / SIEM tools – only app + fraud tiers can reach it    |

### How this prevents lateral movement

- Malware on an ATM can only ever talk to the **ALB edge SG**.
- The ALB cannot reach the DB directly; it must go through the **core app SG**.
- The **core DB SG** only accepts DB traffic from the core app SG, not from ATM or fraud tiers.
- Fraud/AML analytics systems **never see the DB directly** – they consume logs/events via the logging tools SG.
- Logging tools are not Internet-facing and can only be reached from the app + fraud tiers.

This matches how a real Tier-1 bank would argue that:

> “Our ATM network and fraud systems are **logically and technically separated** from the core ledger. Even if an ATM is compromised, security groups and route tables ensure it cannot pivot into the DB tier.”

### Week-2 Lesson Learned

Network micro-segmentation is not just about “more subnets” – it’s about **enforcing explicit trust boundaries**:

- Edge/ATM → App → DB is a **one-way, narrow path**.
- Fraud/AML operates on **derived data and logs**, not on the raw core DB.
- Logging and security tooling are **internal-only safety layers**, not another way into production.

This Week-2 implementation gives me a concrete story to explain **how I would stop ATM malware from ever touching a core banking database** using AWS VPC, route tables, and security groups.

---

🔐 Week 3 — Security Groups vs NACLs (Default-Deny in a Tier-1 Financial Environment)

Objective

Enforce Zero-Trust network segmentation using Security Groups (identity-based controls) and Network ACLs (subnet guardrails) to:

Stop lateral movement

Prevent test → production leakage

Meet PCI DSS, SOC 2, FFIEC, and NIST Zero Trust expectations

---
## Week 3 – SG vs NACL: Default-Deny in a Tier-1 Banking VPC

In Week 3 I focused on **hardening east–west traffic** inside the VPC by combining:

- **Security Groups (SGs)** as *stateful, workload-level firewalls*; and  
- **Network ACLs (NACLs)** as *stateless, subnet-level guardrails* with default-deny.

This is where the lab starts to look like a real Tier-1 bank network rather than a demo VPC.

### 3.1 Security Groups per Tier

I now have a distinct SG for each critical banking tier:

- `sg-alb-edge` – Internet-facing ALB / ATM / online-banking edge
- `sg-core-app` – Core-banking application services
- `sg-core-db` – Core-banking database
- `sg-fraud-analytics` – Fraud / AML analytics tier
- `sg-logging-tools` – Logging / SIEM / security-lake collectors

Key rules (implemented in `modules/security/main.tf`):

- **Edge → App only on 443**

  - `sg-core-app` *ingress* allows **HTTPS 443 only** from `sg-alb-edge`.
  - Edge cannot talk directly to DB or logging tiers.

- **App → DB only on DB port**

  - `sg-core-db` *ingress* allows **5432/tcp only** from `sg-core-app`.
  - No other SGs (edge, fraud, logging) can open DB connections.

- **App & Fraud → Logging only on 443**

  - `sg-logging-tools` *ingress* allows **443/tcp** from:
    - `sg-core-app`
    - `sg-fraud-analytics`
  - There is **no ingress from 0.0.0.0/0** to logging.

- **Strict DB outbound**

  - `sg-core-db` egress is reduced from “any internal 10.0.0.0/16” to a **small, explicit backup CIDR** (`db_backup_cidrs`, example `10.0.240.0/24`).
  - This models a **separate backup / ops network** reached via TGW or a dedicated VPC, which is how Tier-1 banks typically handle backups for PCI/critical data.

This SG design means:

- ATMs and browsers can *only* reach the **edge tier**, not DBs.
- Core apps can *only* reach the DB and logging tiers on the **exact ports required**.
- Fraud/AML can see logs and event streams, but **never talks to core DB directly**.

### 3.2 NACLs as Subnet Guardrails

SGs protect **workloads**. In Week 3 I added **NACLs** to protect entire **subnets** and to enforce a **default-deny posture** for sensitive tiers.

Implemented in `modules/nacls/main.tf` (invoked from `module "nacls"` in `project-1-zero-trust/main.tf`):

- **DB Subnet NACL**

  - *Inbound allow*:
    - 5432/tcp from **core-app subnets only**.
    - Ephemeral ports (1024–65535) for return traffic to the app tier.
  - *Inbound deny*:
    - Any other source CIDR trying to hit DB ports is implicitly blocked.
  - *Outbound allow*:
    - Ephemeral ports back to core-app subnets.
    - Optional controlled access to the backup CIDR (`10.0.240.0/24`) if used.
  - Result: even if an SG is misconfigured later, **non-app subnets cannot talk to DB subnets**.

- **Logging Subnet NACL**

  - *Inbound allow*:
    - 443/tcp from **core-app** and **fraud-analytics** subnet CIDRs.
  - *Inbound deny*:
    - Any traffic from `0.0.0.0/0` or public/edge ranges.
    - Any traffic from non-logging-approved subnets.
  - *Outbound allow*:
    - Internal 10.0.0.0/16 (for shipping logs to SIEM / security lake).
  - Result: logging becomes a **one-way sink** for telemetry – workloads send logs in, but cannot use logging subnets as a lateral-movement pivot.

### 3.3 Stopping Lateral Movement

Combined SG + NACL controls now stop common lateral-movement paths:

- **ATM malware → DB**  
  - Edge SG (`sg-alb-edge`) cannot reach DB SG (`sg-core-db`) at all.
  - DB NACLs only accept 5432 from core-app subnet CIDRs.
  - Even if an attacker compromises an ATM or edge node, **they cannot pivot directly into core DB**.

- **Compromised fraud analytics → DB**  
  - `sg-fraud-analytics` has **no rule** to talk to `sg-core-db`.
  - DB NACLs also drop any 5432 connections originating from fraud-analytics subnets.

- **Abusing logging tier as a jump box**  
  - Logging SG only allows ingress from app + fraud SGs on 443.
  - Logging NACL blocks any inbound from public / unapproved subnets.
  - There is no SSH/RDP allowed, and outbound is restricted to internal networks only.

### 3.4 Preventing Test → Prod Leakage

In a real Tier-1 bank, test environments must **never** reach production fraud or core-banking services.

In this lab I prepare for that by:

- Using **environment-aware tags and variables** (`Environment = dev/test/prod`).
- Designing CIDR blocks so that each environment gets **dedicated non-overlapping ranges**.
- Planning NACL policies per environment so that:
  - `dev` and `test` NACLs **cannot target prod CIDRs**, especially DB and fraud subnets.
  - Terraform will encode these rules so that cross-environment access is structurally impossible, not just a “best-effort” process document.

This sets up the pattern where:

> **Any test → prod connectivity must be deliberately added and code-reviewed in Terraform**, which aligns with FFIEC / OSFI expectations around segmentation and change control.

### 3.5 Week-3 Lesson Learned

> Security Groups are the **surgical blades** of segmentation (per workload, stateful), while NACLs are the **concrete walls** (per subnet, stateless).

By combining both with a **default-deny mindset**:

- Lateral movement is stopped at **multiple layers** (SG and NACL).
- Sensitive tiers (DB, logging) only ever see traffic from **known subnet ranges and SGs**.
- Environment boundaries (dev/test/prod) can be enforced in code so that “test reaching prod” becomes a **Terraform diff**, not a surprise in production.
