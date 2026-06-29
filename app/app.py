from flask import Flask, request, jsonify, redirect
import string, random

app = Flask(__name__)

# In-memory store for now (Layer 3 swaps this for RDS)
urls = {}

def make_code(n=6):
    return "".join(random.choices(string.ascii_letters + string.digits, k=n))

@app.route("/")
def home():
    return jsonify(message="URL Shortener API", version="1.0", endpoints=["/shorten", "/health"])

@app.route("/health")
def health():
    return jsonify(status="broken"), 500

@app.route("/shorten", methods=["POST"])
def shorten():
    data = request.get_json(silent=True) or {}
    long_url = data.get("url")
    if not long_url:
        return jsonify(error="missing 'url'"), 400
    code = make_code()
    urls[code] = long_url
    return jsonify(short_code=code, short_url=f"/{code}", original=long_url)

@app.route("/<code>")
def follow(code):
    target = urls.get(code)
    if not target:
        return jsonify(error="not found"), 404
    return redirect(target)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
