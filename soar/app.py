import logging
import os
import secrets
from datetime import datetime, timezone
from uuid import uuid4

from flask import Flask, Response, g, jsonify, request
from time import perf_counter

from prometheus_client import (
    CONTENT_TYPE_LATEST,
    Counter,
    Histogram,
    generate_latest,
)

from rule_engine import evaluate_event
from actions import execute_actions

logging.basicConfig(level=logging.INFO)

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = 64 * 1024

API_TOKEN = os.environ.get("SOAR_API_TOKEN")

if not API_TOKEN:
    raise RuntimeError("Set the SOAR_API_TOKEN environment variable.")

ALLOWED_SEVERITIES = {"low", "medium", "high", "critical"}

EVENT_REQUESTS = Counter(
    "soar_event_requests_total",
    "Requests to the event endpoint",
    ["http_status"]
)

VALID_EVENTS = Counter(
    "soar_valid_events_total",
    "Security events that passed validation"
)

ACTION_RESULTS = Counter(
    "soar_action_results_total",
    "Results returned by response actions",
    ["action", "status"]
)

EVENT_DURATION = Histogram(
    "soar_event_request_duration_seconds",
    "Time spent handling event requests",
    buckets=(0.01, 0.1, 0.5, 1, 5, 15, 30, 60, 120)
)


@app.before_request
def start_event_timer():
    if request.endpoint == "receive_event":
        g.event_started_at = perf_counter()


@app.after_request
def record_event_request(response):
    if request.endpoint == "receive_event":
        EVENT_REQUESTS.labels(
            http_status=str(response.status_code)
        ).inc()

        started_at = getattr(g, "event_started_at", None)

        if started_at is not None:
            EVENT_DURATION.observe(perf_counter() - started_at)

    return response


@app.get("/metrics")
def metrics():
    return Response(
        generate_latest(),
        content_type=CONTENT_TYPE_LATEST
    )


@app.get("/health")
def health():
    return jsonify({
        "status": "ok",
        "service": "innovatech-soar",
        "version": "0.2.0"
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

    VALID_EVENTS.inc()

    evaluation = evaluate_event(normalised_event)

    event_record = {
        "event_id": event_id,
        "received_at": received_at,
        "event": normalised_event
    }

    action_results = execute_actions(
        evaluation["selected_actions"],
        event_record
    )

    for result in action_results:
        ACTION_RESULTS.labels(
            action=result["action"],
            status=result["status"]
        ).inc()

    app.logger.info(
        "Event evaluated: id=%s matched_rules=%s selected_actions=%s",
        event_id,
        evaluation["matched_rules"],
        evaluation["selected_actions"]
    )

    return jsonify({
        "status": "processed",
        "event_id": event_id,
        "received_at": received_at,
        "event": normalised_event,
        "matched_rules": evaluation["matched_rules"],
        "selected_actions": evaluation["selected_actions"],
        "action_results": action_results
    }), 200
