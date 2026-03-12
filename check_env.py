import os
import stat
import socket
import urllib.request
import urllib.error
import json
import sys

BASE = '/Users/kamran/Desktop/TestPy'
STATIC = os.path.join(BASE, 'static')
FILES = [
    os.path.join(BASE, 'app.py'),
    os.path.join(BASE, 'requirements.txt'),
    os.path.join(STATIC, 'index.html'),
    os.path.join(STATIC, 'main.js'),
    os.path.join(STATIC, 'styles.css'),
    os.path.join(BASE, 'README.md'),
]

def print_hdr(s):
    print('\n' + '='*60)
    print(s)
    print('='*60)

def check_files():
    print_hdr('Filesystem checks')
    for f in FILES:
        if os.path.exists(f):
            st = os.stat(f)
            mode = stat.filemode(st.st_mode)
            print(f'{f}: exists, mode={mode}, uid={st.st_uid}, size={st.st_size}')
        else:
            print(f'{f}: MISSING')

def check_port(host='127.0.0.1', port=5000):
    print_hdr(f'TCP connect check to {host}:{port}')
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(2.0)
    try:
        s.connect((host, port))
        print(f'OK: connected to {host}:{port}')
    except Exception as e:
        print(f'FAILED: cannot connect to {host}:{port} -> {e}')
    finally:
        s.close()

def http_get(path):
    url = f'http://127.0.0.1:5000{path}'
    print_hdr(f'HTTP GET {url}')
    req = urllib.request.Request(url, headers={'User-Agent':'check_env/1.0'})
    try:
        with urllib.request.urlopen(req, timeout=4) as resp:
            body = resp.read()
            content = body.decode('utf-8', errors='replace')
            print(f'STATUS: {resp.status} {resp.reason}')
            ct = resp.getheader('Content-Type')
            print(f'Content-Type: {ct}')
            # Print short body preview
            preview = content.strip()
            if len(preview) > 800:
                preview = preview[:800] + '...'
            print('BODY PREVIEW:')
            print(preview)
    except urllib.error.HTTPError as he:
        try:
            body = he.read().decode('utf-8', errors='replace')
        except:
            body = '<no body>'
        print(f'HTTP ERROR: {he.code} {he.reason}')
        print('BODY:')
        print(body)
    except urllib.error.URLError as ue:
        print(f'URL ERROR: {ue}')
    except Exception as e:
        print(f'ERROR: {e}')

def main():
    check_files()
    check_port()
    http_get('/status')
    http_get('/')
    print_hdr('Done')
    print('If you see connection errors or HTTP 403, paste the output here and I will suggest exact fixes.')

if __name__ == '__main__':
    main()
