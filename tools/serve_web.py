"""Serve the static build; optional local-only real-controller QA fixtures are never deployed."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import argparse
import json

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=8063)
    parser.add_argument('--qa', action='store_true')
    args = parser.parse_args()
    class Handler(SimpleHTTPRequestHandler):
        extensions_map = {**SimpleHTTPRequestHandler.extensions_map, '.wasm': 'application/wasm', '.js': 'text/javascript'}

        def do_GET(self):
            if args.qa and self.path.split('?')[0] == '/qa-fixtures.json':
                routes = []
                for index in range(45):
                    path = ROOT / f'tests/fixtures/chapter_{index//10+1:02}_room_{index%10+1:02}.json'
                    routes.append({'index': index, 'inputs': json.loads(path.read_text())})
                data = json.dumps({'routes': routes, 'repetitions': 3, 'accelerated': True}).encode()
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Content-Length', str(len(data)))
                self.end_headers()
                self.wfile.write(data)
                return
            super().do_GET()

    print(f'Threadrunner: http://127.0.0.1:{args.port}/', flush=True)
    ThreadingHTTPServer(('127.0.0.1', args.port), partial(Handler, directory=str(ROOT / 'builds/web'))).serve_forever()


if __name__ == '__main__':
    main()
