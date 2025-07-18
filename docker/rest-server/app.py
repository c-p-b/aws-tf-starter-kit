import json
import os

def handler(event, context):
    """Lambda handler that acts as a REST API"""
    
    # Check API key authentication
    api_key = os.environ.get('API_KEY')
    if api_key:
        headers = event.get('headers', {})
        provided_key = headers.get('x-api-key') or headers.get('X-API-Key')
        
        if provided_key != api_key:
            return {
                'statusCode': 401,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({'error': 'Unauthorized'})
            }
    
    # Extract HTTP method and path
    http_method = event.get('httpMethod', 'GET')
    path = event.get('path', '/')
    
    # Simple routing
    if path == '/health':
        response = {
            'status': 'healthy',
            'service': os.environ.get('SERVICE_NAME', 'rest-server'),
            'environment': os.environ.get('ENVIRONMENT', 'unknown')
        }
        status_code = 200
    elif path == '/info':
        response = {
            'version': '1.0.0',
            'runtime': 'python3.11',
            'container': True
        }
        status_code = 200
    else:
        response = {
            'message': f'Hello from containerized Lambda!',
            'path': path,
            'method': http_method
        }
        status_code = 200
    
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'X-Service-Type': 'lambda-container'
        },
        'body': json.dumps(response)
    }