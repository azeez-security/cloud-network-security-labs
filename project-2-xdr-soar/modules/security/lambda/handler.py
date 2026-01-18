import json
import os
import datetime
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")
ec2 = boto3.client("ec2")
iam = boto3.client("iam")

PROJECT_NAME = os.getenv("PROJECT_NAME", "project-2-xdr-soar")
EVIDENCE_BUCKET = os.getenv("EVIDENCE_BUCKET", "")

ENABLE_IAM_DISABLE = os.getenv("ENABLE_IAM_DISABLE", "false").lower() == "true"
ENABLE_EC2_QUARANTINE = os.getenv("ENABLE_EC2_QUARANTINE", "false").lower() == "true"
ENABLE_SNAPSHOT = os.getenv("ENABLE_SNAPSHOT", "false").lower() == "true"

QUARANTINE_SG_ID = os.getenv("QUARANTINE_SG_ID", "")


def _now():
    return datetime.datetime.utcnow().replace(tzinfo=datetime.timezone.utc).isoformat()


def _put_evidence(key: str, payload: dict):
    if not EVIDENCE_BUCKET:
        return
    s3.put_object(
        Bucket=EVIDENCE_BUCKET,
        Key=key,
        Body=json.dumps(payload, indent=2).encode("utf-8"),
        ContentType="application/json",
    )


def _extract_findings(event: dict):
    detail = event.get("detail", {})
    findings = detail.get("findings", [])
    return findings if isinstance(findings, list) else []


def _finding_types(finding: dict):
    return finding.get("Types", []) or []


def _severity_label(finding: dict):
    sev = finding.get("Severity", {}) or {}
    return (sev.get("Label") or "UNKNOWN").upper()


def _resource_ids(finding: dict):
    resources = finding.get("Resources", []) or []
    out = []
    for r in resources:
        out.append({
            "type": r.get("Type"),
            "id": r.get("Id"),
            "region": r.get("Region"),
        })
    return out


def _try_extract_ec2_instance_id(finding: dict):
    for r in (finding.get("Resources", []) or []):
        if (r.get("Type") or "").upper() == "AWS_EC2_INSTANCE":
            rid = r.get("Id", "")
            if "/instance/" in rid:
                return rid.split("/instance/")[-1]
            if "instance/" in rid:
                return rid.split("instance/")[-1]
            if rid.startswith("i-"):
                return rid
    return ""


def _try_extract_iam_username(finding: dict) -> str:
    # Best-effort: parse username from the IAM user ARN in Resources
    for r in (finding.get("Resources", []) or []):
        rid = (r.get("Id") or "")
        # arn:aws:iam::123456789012:user/azeez.admin
        if ":user/" in rid:
            return rid.split(":user/")[-1].strip()
        if "/user/" in rid:
            return rid.split("/user/")[-1].strip()
    return ""


def _quarantine_ec2(instance_id: str):
    if not (ENABLE_EC2_QUARANTINE and QUARANTINE_SG_ID and instance_id):
        return {"attempted": False, "reason": "disabled/missing inputs"}

    desc = ec2.describe_instances(InstanceIds=[instance_id])
    nis = desc["Reservations"][0]["Instances"][0]["NetworkInterfaces"]
    eni_id = nis[0]["NetworkInterfaceId"]

    ec2.modify_network_interface_attribute(
        NetworkInterfaceId=eni_id,
        Groups=[QUARANTINE_SG_ID],
    )
    return {"attempted": True, "eni": eni_id, "quarantine_sg": QUARANTINE_SG_ID}


def _snapshot_instance_volumes(instance_id: str):
    if not (ENABLE_SNAPSHOT and instance_id):
        return {"attempted": False, "reason": "disabled/missing instance_id"}

    desc = ec2.describe_instances(InstanceIds=[instance_id])
    inst = desc["Reservations"][0]["Instances"][0]
    mappings = inst.get("BlockDeviceMappings", []) or []

    snap_ids = []
    for m in mappings:
        ebs = m.get("Ebs")
        if not ebs:
            continue
        vol_id = ebs.get("VolumeId")
        if not vol_id:
            continue

        snap = ec2.create_snapshot(
            VolumeId=vol_id,
            Description=f"{PROJECT_NAME} SOAR snapshot for {instance_id} at {_now()}",
            TagSpecifications=[{
                "ResourceType": "snapshot",
                "Tags": [
                    {"Key": "Project", "Value": PROJECT_NAME},
                    {"Key": "SOAR", "Value": "true"},
                    {"Key": "InstanceId", "Value": instance_id},
                ],
            }],
        )
        snap_ids.append(snap["SnapshotId"])

    return {"attempted": True, "snapshots": snap_ids}


def _disable_iam_user_from_finding(finding: dict):
    if not ENABLE_IAM_DISABLE:
        return {"attempted": False, "reason": "disabled"}

    user = ""
    for k in ["UserName", "Username", "userName", "user"]:
        if finding.get(k):
            user = finding.get(k)
            break

    if not user:
        pf = finding.get("ProductFields", {}) or {}
        user = pf.get("aws/iamUserName") or pf.get("IamUserName") or ""

    # NEW: try extracting from Resources ARN
    if not user:
        user = _try_extract_iam_username(finding)

    if not user:
        return {"attempted": False, "reason": "no username extracted"}

    keys = iam.list_access_keys(UserName=user).get("AccessKeyMetadata", [])
    changed = []
    for k in keys:
        akid = k["AccessKeyId"]
        iam.update_access_key(UserName=user, AccessKeyId=akid, Status="Inactive")
        changed.append(akid)

    return {"attempted": True, "username": user, "access_keys_deactivated": changed}


def lambda_handler(event, context):
    logger.info("SOAR Dispatcher invoked")
    logger.info("Event received: %s", json.dumps(event)[:4000])  # avoid huge logs

    findings = _extract_findings(event)
    logger.warning("SOAR_FINDINGS_COUNT=%d", len(findings))
    results = []

    actions_count = 0
    errors_count = 0

    for f in findings:
        fid = f.get("Id", "unknown")
        sev = _severity_label(f)
        types = _finding_types(f)
        instance_id = _try_extract_ec2_instance_id(f)

        action_result = {
            "finding_id": fid,
            "severity": sev,
            "types": types,
            "resources": _resource_ids(f),
            "instance_id": instance_id,
            "actions": {},
            "timestamp": _now(),
        }

        try:
            # Ransomware / related -> quarantine + snapshot (if enabled)
            if any(t.startswith("Backdoor:EC2/Ransomware") or "Ransomware" in t for t in types):
                action_result["actions"]["quarantine_ec2"] = _quarantine_ec2(instance_id)
                action_result["actions"]["snapshot"] = _snapshot_instance_volumes(instance_id)

            # Cryptomining -> quarantine (if enabled)
            if any(t.startswith("CryptoCurrency:EC2") for t in types):
                action_result["actions"]["quarantine_ec2"] = _quarantine_ec2(instance_id)

            # IAM unauthorized access -> disable IAM user (if enabled)
            if any(t.startswith("UnauthorizedAccess:IAMUser") for t in types):
                action_result["actions"]["disable_iam_user"] = _disable_iam_user_from_finding(f)

        except Exception as e:
            logger.exception("Action failed for finding %s", fid)
            action_result["actions"]["error"] = str(e)
            errors_count += 1

        # Count actions attempted (excluding 'error')
        actions_count += len([k for k in action_result["actions"].keys() if k != "error"])

        # Evidence write (always)
        evidence_key = f"evidence/{PROJECT_NAME}/{datetime.date.today().isoformat()}/{fid}.json"
        _put_evidence(evidence_key, {"event": event, "result": action_result})

        results.append(action_result)

    response = {
        "statusCode": 200,
        "incident_id": getattr(context, "aws_request_id", "n/a"),
        "findings_processed": len(results),
        "actions_count": actions_count,
        "errors_count": errors_count,
        "results": results,
    }

    logger.info("SOAR_RESPONSE: %s", json.dumps(response)[:4000])
    return response
