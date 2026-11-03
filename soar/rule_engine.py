import json
from pathlib import Path

RULES_PATH = Path(__file__).with_name("rules.json")

with RULES_PATH.open(encoding="utf-8") as file:
    RULES = json.load(file)


def evaluate_event(event):
    matched_rules = []
    selected_actions = []

    for rule in RULES:
        if (
            event["event_type"] == rule["event_type"]
            and event["severity"] in rule["severities"]
        ):
            matched_rules.append(rule["name"])

            for action in rule["actions"]:
                if action not in selected_actions:
                    selected_actions.append(action)

    return {
        "matched_rules": matched_rules,
        "selected_actions": selected_actions
    }