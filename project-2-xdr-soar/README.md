### Project 2 — Autonomous XDR + SOAR Platform for Cloud Banking

Ransomware | IAM Credential Abuse | Automated Incident Response

## Executive Summary

This project implements a production-grade, event-driven XDR + SOAR architecture on AWS, designed to detect, triage, and automatically respond to high-risk cloud security incidents while preserving immutable forensic evidence for audit and investigation.

The solution demonstrates how banking and fintech SOC teams can move from alert-driven monitoring to policy-driven, automated containment, reducing MTTR without compromising operational safety or compliance.

## Business & Security Outcomes (Tier-1 Banking Lens)

Automated detection and response for high-confidence threats

Guardrail-based remediation (no unsafe shutdowns)

Full forensic traceability for audits and post-incident review

Serverless, scalable security automation aligned with Zero Trust principles

Core Capabilities Demonstrated

XDR Signal Correlation
Centralized normalization of GuardDuty findings via AWS Security Hub.

SOAR Decision Engine
Severity-aware, threat-type-aware response routing using Lambda.

Automated Containment
EC2 quarantine, forensic snapshot creation, and IAM access key deactivation.

Evidence-First Design
Immutable, structured JSON artifacts written to S3 for every incident.

## Architecture Overview
# Detection & Response Flow

Amazon GuardDuty detects threats such as ransomware activity and IAM abuse

AWS Security Hub normalizes findings into a common schema

Amazon EventBridge filters and routes relevant findings in real time

SOAR Dispatcher (AWS Lambda) evaluates severity and context

Automated remediation is executed based on policy

Forensic evidence is written to Amazon S3

Execution lifecycle is logged in CloudWatch

## Architecture Diagram (ASCII)

[ GuardDuty ]
     |
     v
[ Security Hub ]
     |
     v
[ EventBridge ]
     |
     v
[ SOAR Dispatcher (Lambda) ]
     |              |
     |              |
     v              v
[ EC2 Response ]  [ IAM Response ]
  - Quarantine      - Disable Keys
  - Snapshot
        \            /
         \          /
          v        v
     [ S3 Evidence Store ]
     - Immutable JSON
     - Metadata
     - Audit Trail

(All actions logged in CloudWatch Logs)

GuardDuty produces raw detections, Security Hub normalizes them, EventBridge applies routing logic, and a Lambda-based SOAR engine enforces guardrails — quarantining EC2, disabling IAM keys, and persisting immutable evidence in S3 for audit and post-incident review.

## SOAR Logic Highlights

Severity-based decision engine (HIGH / CRITICAL focus)

Modular remediation actions (EC2, IAM, Evidence)

Feature flags for safe enable/disable of auto-response

Deterministic Lambda packaging via Terraform

Designed for future expansion (WAF, fraud, bot defense)

## Security & Engineering Best Practices

Infrastructure as Code (Terraform)

Least-privilege IAM policies

Event-driven, serverless architecture

Immutable, versioned forensic evidence

SOC-aligned incident response patterns

## Evidence & Validation

CloudWatch Logs

Lambda START / END lifecycle

Execution duration, memory usage, returned JSON output

S3 Evidence Store
/project-2-xdr-soar/evidence/2026/01/17/24f811b0-3cf0-46ab-a113-5c88c315532d/_summary.json

## Terraform Structure

terraform/ – root deployment configuration

modules/security/ – GuardDuty, Security Hub, EventBridge, SOAR Lambda, S3 evidence

## Enterprise Use Cases

Automated containment of compromised EC2 instances

Rapid IAM credential revocation

SOC alert fatigue reduction

Audit-ready forensic evidence retention

Cloud-native SOAR reference architecture