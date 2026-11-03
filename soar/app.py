from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/health")
def health():
    return jsonify({
        "status": "ok",
        "service": "innovatech-soar"
    }), 200