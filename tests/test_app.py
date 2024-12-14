import tfgha.app

def test_app():
    assert tfgha.app.hello() == "Hello from Python deployed with poetry"
