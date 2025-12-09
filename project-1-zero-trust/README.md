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

### Real-World Challenge & Lesson Learned

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

### CIDR Allocation Strategy (Tier-1 Friendly)

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

---

### Week-1 Lesson Learned

> CIDR design is not just a subnetting exercise; it’s a **risk and cost decision**.

By planning the `/16` and `/20` blocks up front, the bank avoids:

- Peering failures due to overlapping CIDRs between regions.
- Costly **re-architecture** when new digital products (e.g., instant payments, new ATM networks) come online.
- Exposure from mis-segmented workloads (fraud/AML sharing networks with core transactional systems).

This lab shows how to document and enforce a **bank-grade CIDR strategy** in Terraform so future changes stay controlled.
