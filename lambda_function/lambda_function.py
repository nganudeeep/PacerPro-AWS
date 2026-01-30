import json
import os
import boto3
from datetime import datetime, timezone

ec2 = boto3.client("ec2")
sns = boto3.client("sns")

INSTANCE_ID = os.environ["INSTANCE_ID"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
SHARED_SECRET = os.environ.get("SHARED_SECRET", "")

def lambda_handler(event, context):
    headers = event.get("headers") or {}
    provided = headers.get("x-shared-secret") or headers.get("X-Shared-Secret")

    if SHARED_SECRET and provided != SHARED_SECRET:
        print("Unauthorized request (secret mismatch).")
        return {"statusCode": 401, "body": "unauthorized"}

    received_at = datetime.now(timezone.utc).isoformat()

    body = event.get("body")
    try:
        payload = json.loads(body) if isinstance(body, str) else (body or {})
    except Exception:
        payload = {"raw_body": body}

    print(f"[{received_at}] Alert received. Rebooting instance {INSTANCE_ID}. Payload={payload}")

    ec2.reboot_instances(InstanceIds=[INSTANCE_ID])

    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=f"Auto-remediation: rebooted {INSTANCE_ID}",
        Message=json.dumps(
            {"time": received_at, "instance_id": INSTANCE_ID, "action": "reboot", "alert": payload},
            indent=2
        ),
    )
    return {"statusCode": 200, "body": "ok"}
