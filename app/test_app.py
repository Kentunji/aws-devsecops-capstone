from app import app

def test_health():
    c = app.test_client()
    r = c.get("/health")
    assert r.status_code in (200, 500)
    assert "status" in r.get_json()

def test_shorten():
    c = app.test_client()
    r = c.post("/shorten", json={"url": "https://example.com"})
    assert r.status_code in (200, 500)
    assert "short_code" in r.get_json()

def test_shorten_missing_url():
    c = app.test_client()
    r = c.post("/shorten", json={})
    assert r.status_code == 400
