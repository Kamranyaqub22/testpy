# TestPy Calculator

1. Create virtual env:
   python3 -m venv .venv
   source .venv/bin/activate

2. Install:
   pip install -r requirements.txt

3. Run:
   python app.py

4. Open:
   http://127.0.0.1:5000/

Troubleshooting 403 when opening http://127.0.0.1:5000/
1. Confirm server is running and view logs:
   cd /Users/kamran/Desktop/TestPy
   python app.py
   (watch the console output for errors)

2. Test endpoints:
   curl -v http://127.0.0.1:5000/status
   curl -v http://127.0.0.1:5000/

   - /status should return JSON {"status":"ok"}.
   - If / returns 403, read the server log printed by app.py for the permission error.

3. Check file presence & permissions:
   ls -l static/index.html
   # ensure readable by the user running Flask, e.g.:
   chmod a+r static/index.html

4. If you run behind a proxy (nginx/Apache), ensure the proxy isn't returning 403 and that it forwards to 127.0.0.1:5000.

5. Helpful diagnostics:
   # see process listening on port 5000
   sudo ss -ltnp | grep 5000
   # or (Linux) netstat -ltnp | grep 5000

If you run the server and /status returns ok but accessing / still gives 403, check file permissions (step 3) and paste the console log lines from app.py here and I'll help interpret them.
