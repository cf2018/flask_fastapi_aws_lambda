from __future__ import annotations

import os
from flask import Flask, render_template
import requests


def create_app() -> Flask:
    app = Flask(__name__, template_folder="templates")

    # Resolve FastAPI endpoint: prefer env var, default to local dev
    fastapi_endpoint = os.getenv("FASTAPI1_ENDPOINT", "http://localhost:8000")

    @app.route("/")
    def index():
        # Call FastAPI root ("/") which returns JSON {"message": ...}
        url = fastapi_endpoint.rstrip("/") + "/"
        try:
            resp = requests.get(url, timeout=5)
            resp.raise_for_status()
            payload = resp.json()
            message = payload.get("message", str(payload))
            error = None
        except Exception as e:
            message = None
            error = f"Failed to call FastAPI at {url}: {e}"

        return render_template("index.html", fastapi_endpoint=fastapi_endpoint, message=message, error=error)

    return app


app = create_app()

if __name__ == "__main__":
    # Local dev server for Flask
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")), debug=True)
