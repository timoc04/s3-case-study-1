import logging
import os
import secrets
from datetime import datetime, timezone
from uuid import uuid4

from flask import Flask, jsonify, request
from rule_engine import evaluate_event

logging.basicConfig(level=logging.INFO)

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = 64 * 1024

API_TOKEN = os.environ.get("SOAR_API_TOKEN")

if not API_TOKEN:
    raise RuntimeError("Set the SOAR_API_TOKEN environment variable.")

ALLOWED_SEVERITIES = {"low", "medium", "high", "critical"}


@app.get("/health")
def health():
    return jsonify({
        "status": "ok",
        "service": "innovatech-soar"
    }), 200


@app.post("/events")
def receive_event():
    supplied_token = request.headers.get("Authorization", "")

    if not secrets.compare_digest(
        supplied_token, f"Bearer {API_TOKEN}"
    ):
        return jsonify({"error": "Unauthorised"}), 401

    if not request.is_json:
        return jsonify({"error": "Content-Type must be application/json"}), 415

    event = request.get_json(silent=True)

    if not isinstance(event, dict):
        return jsonify({"error": "Body must be a valid JSON object"}), 400

    required_fields = ("event_type", "source", "severity")

    for field in required_fields:
        value = event.get(field)

        if not isinstance(value, str) or not value.strip():
            return jsonify({
                "error": f"{field} must be a non-empty string"
            }), 400

        if len(value) > 200:
            return jsonify({
                "error": f"{field} must not exceed 200 characters"
            }), 400

    severity = event["severity"].strip().lower()

    if severity not in ALLOWED_SEVERITIES:
        return jsonify({
            "error": "severity must be low, medium, high or critical"
        }), 400

    event_id = str(uuid4())
    received_at = datetime.now(timezone.utc).isoformat()

    normalised_event = {
        "event_type": event["event_type"].strip(),
        "source": event["source"].strip(),
        "severity": severity
    }

    evaluation = evaluate_event(normalised_event)

    app.logger.info(
        "Event evaluated: id=%s matched_rules=%s selected_actions=%s",
        event_id,
        evaluation["matched_rules"],
        evaluation["selected_actions"]
    )

    return jsonify({
        "status": "evaluated",
        "event_id": event_id,
        "received_at": received_at,
        "event": normalised_event,
        "matched_rules": evaluation["matched_rules"],
        "selected_actions": evaluation["selected_actions"]
    }), 200