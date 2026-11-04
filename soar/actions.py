import json
import logging
import os
from pathlib import Path

logger = logging.getLogger(__name__)

DATA_DIRECTORY = Path(
    os.environ.get(
        "SOAR_DATA_DIR",
        str(Path(__file__).parent / "data")
    )
)


def execute_actions(action_names, event_record):
    results = []

    for action_name in action_names:
        if action_name != "security_notification":
            results.append({
                "action": action_name,
                "status": "not_implemented"
            })
            continue

        notification = {
            **event_record,
            "action": action_name,
            "message": "Security event requires administrator attention."
        }

        try:
            directory = DATA_DIRECTORY / "notifications"
            directory.mkdir(parents=True, exist_ok=True)

            filename = f"{event_record['event_id']}.json"
            destination = directory / filename

            with destination.open("x", encoding="utf-8") as file:
                json.dump(notification, file, indent=2)

            logger.info(
                "Security notification created: event_id=%s",
                event_record["event_id"]
            )

            results.append({
                "action": action_name,
                "status": "succeeded",
                "notification_file": filename
            })

        except OSError:
            logger.exception(
                "Notification storage failed: event_id=%s",
                event_record["event_id"]
            )

            results.append({
                "action": action_name,
                "status": "failed",
                "error": "Notification could not be stored"
            })

    return results