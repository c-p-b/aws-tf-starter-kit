def handler(event, context):
    """Test Lambda handler"""
    return {
        'statusCode': 200,
        'body': 'Hello from test Lambda!'
    }