import subprocess
import platform
import re
import time
from flask import Flask, request, jsonify
from datetime import datetime
import os

app = Flask(__name__)

def ping_host(host, count=4, timeout=30):
    param = '-n' if platform.system().lower() == 'windows' else '-c'
    command = ['ping', param, str(count), host]

    try:
        result = subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=timeout
        )

        if result.returncode == 0:
            output = result.stdout
            avg_latency = parse_latency(output)
            return True, avg_latency, output
        else:
            return False, None, result.stderr
    except subprocess.TimeoutExpired:
        return False, None, f"Ping to {host} timed out after {timeout} seconds."
    except subprocess.SubprocessError as e:
        return False, None, f"Error executing ping to {host}: {e}"

def parse_latency(output):
    try:
        if platform.system().lower() == 'windows':
            match = re.search(r'Average = (\d+)ms', output)
            return float(match.group(1)) if match else None
        else:
            match = re.search(r'(\d+\.\d+)/(\d+\.\d+)/(\d+\.\d+)', output)
            return float(match.group(2)) if match else None
    except Exception:
        return None

@app.route('/latency', methods=['GET'])
def latency_check():
    default_host = os.getenv('PING_HOST', '8.8.8.8')
    host = request.args.get('host', default_host)
    ping_count = 1
    timeout = 30

    success, avg_latency, output = ping_host(host, ping_count, timeout)
    response = {
        'host': host,
        'timestamp': datetime.now().strftime('%Y-%m-%d %H:%M:%S %Z'),
        'status': 'reachable' if success else 'unreachable',
        'average_latency_ms': round(avg_latency, 2) if avg_latency else None,
    }

    return jsonify(response)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)