import subprocess
import threading
import time
from flask import Flask, jsonify

TARGET_HOST = "8.8.8.8"
PING_INTERVAL = 5

app = Flask(__name__)
latency_data = {"latency_ms": None}

def measure_latency():
    while True:
        try:
            result = subprocess.run(
                ["ping", "-c", "1", "-W", "1", TARGET_HOST],
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                # Parse output for latency
                for line in result.stdout.splitlines():
                    if "time=" in line:
                        latency_str = line.split("time=")[-1].split(" ")[0]
                        latency_data["latency_ms"] = float(latency_str)
                        break
            else:
                latency_data["latency_ms"] = None
        except Exception as e:
            latency_data["latency_ms"] = None
        time.sleep(PING_INTERVAL)

@app.route("/latency")
def get_latency():
    return jsonify(latency_data)

if __name__ == "__main__":
    thread = threading.Thread(target=measure_latency, daemon=True)
    thread.start()

    app.run(host="0.0.0.0", port=5000)
