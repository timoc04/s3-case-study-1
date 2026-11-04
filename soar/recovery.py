import logging
import os
import time

import boto3
from botocore.exceptions import BotoCoreError, ClientError

logger = logging.getLogger(__name__)


def recover_service(event_record):
    result = {"action": "service_recovery"}

    if event_record["event"]["source"] != "soar-test-service":
        return {
            **result,
            "status": "rejected",
            "error": "Source is not an authorised recovery target"
        }

    instance_id = os.environ.get("SOAR_RECOVERY_INSTANCE_ID")

    if not instance_id:
        return {
            **result,
            "status": "failed",
            "error": "SOAR_RECOVERY_INSTANCE_ID is not configured"
        }

    command_id = None

    try:
        ssm = boto3.client("ssm", region_name="eu-central-1")

        response = ssm.send_command(
            InstanceIds=[instance_id],
            DocumentName="AWS-RunShellScript",
            Comment=f"SOAR recovery {event_record['event_id']}",
            TimeoutSeconds=30,
            Parameters={
                "executionTimeout": ["30"],
                "commands": [
                    "set -eu",
                    "systemctl start soar-test-service",
                    "systemctl is-active --quiet soar-test-service",
                    (
                        "curl --fail --silent --show-error "
                        "--retry 5 --retry-connrefused --retry-delay 1 "
                        "--connect-timeout 2 --max-time 3 "
                        "http://127.0.0.1:8081/"
                    )
                ]
            }
        )

        command_id = response["Command"]["CommandId"]
        result["command_id"] = command_id

        for _ in range(30):
            try:
                invocation = ssm.get_command_invocation(
                    CommandId=command_id,
                    InstanceId=instance_id
                )
            except ssm.exceptions.InvocationDoesNotExist:
                time.sleep(2)
                continue

            status = invocation["Status"]

            if status == "Success":
                logger.info(
                    "Service recovery succeeded: event_id=%s command_id=%s",
                    event_record["event_id"],
                    command_id
                )
                return {
                    **result,
                    "status": "succeeded",
                    "output": invocation["StandardOutputContent"].strip()
                }

            if status in {"Failed", "Cancelled", "TimedOut"}:
                return {
                    **result,
                    "status": "failed",
                    "ssm_status": status,
                    "error": invocation["StandardErrorContent"].strip()
                }

            time.sleep(2)

        return {
            **result,
            "status": "pending",
            "message": "Command submitted; final result is not yet available"
        }

    except (BotoCoreError, ClientError):
        logger.exception(
            "Recovery request failed: event_id=%s command_id=%s",
            event_record["event_id"],
            command_id
        )
        return {
            **result,
            "status": "unknown" if command_id else "failed",
            "error": "Could not submit or verify the recovery command"
        }