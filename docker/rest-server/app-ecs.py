from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import os
import signal
import sys

class RESTHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {
                'status': 'healthy',
                'service': os.environ.get('SERVICE_NAME', 'rest-server'),
                'environment': os.environ.get('ENVIRONMENT', 'unknown'),
                'container_type': os.environ.get('CONTAINER_TYPE', 'ecs')
            }
            self.wfile.write(json.dumps(response).encode())
        
        elif self.path == '/info':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {
                'version': '1.0.0',
                'runtime': 'python3.11',
                'port': 8080,
                'pid': os.getpid()
            }
            self.wfile.write(json.dumps(response).encode())
        
        else:
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {
                'message': 'Hello from ECS container!',
                'path': self.path,
                'method': 'GET',
                'headers': dict(self.headers)
            }
            self.wfile.write(json.dumps(response).encode())
    
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        
        response = {
            'message': 'POST received',
            'path': self.path,
            'data': post_data.decode('utf-8')
        }
        self.wfile.write(json.dumps(response).encode())
    
    def log_message(self, format, *args):
        # Log to stdout for CloudWatch
        sys.stdout.write("%s - - [%s] %s\n" %
                         (self.address_string(),
                          self.log_date_time_string(),
                          format%args))
        sys.stdout.flush()

def signal_handler(sig, frame):
    print('Shutting down gracefully...')
    sys.exit(0)

if __name__ == '__main__':
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    port = int(os.environ.get('PORT', 8080))
    server = HTTPServer(('', port), RESTHandler)
    print(f'Starting server on port {port}...')
    sys.stdout.flush()
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    
    server.server_close()
    print('Server stopped.')