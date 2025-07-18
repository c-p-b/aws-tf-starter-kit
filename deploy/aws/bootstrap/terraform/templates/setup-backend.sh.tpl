#!/usr/bin/env bash
set -euo pipefail

echo "🎉 Bootstrap complete!"
echo ""
echo "Your Terraform backend has been configured with:"
echo "  S3 Bucket: ${bucket}"
echo "  DynamoDB Table: ${dynamodb_table}"
echo "  Region: ${region}"
echo ""
echo "To use this backend in your Terraform configurations, add the following to your terraform block:"
echo ""
echo 'terraform {'
echo '  backend "s3" {'
echo '    bucket         = "${bucket}"'
echo '    key            = "path/to/your/project/terraform.tfstate"'
echo '    region         = "${region}"'
echo '    dynamodb_table = "${dynamodb_table}"'
echo '    encrypt        = true'
echo '  }'
echo '}'
echo ""
echo "💡 Tips:"
echo "  - Use different 'key' values for different environments (e.g., preview/lambda/terraform.tfstate)"
echo "  - The backend-config.tf file has been generated with a template you can copy"
echo "  - Run 'make init' in any deploy directory to initialize with the backend"