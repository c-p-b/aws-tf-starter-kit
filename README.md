# AWS Terraform Starter Kit

A production-ready Terraform/OpenTofu starter kit for AWS infrastructure with built-in best practices, testing, and modular design.

## Prerequisites

1. **Install OpenTofu** (or Terraform):
   ```bash
   # macOS
   brew install opentofu
   
   # Linux/Windows - see https://opentofu.org/docs/intro/install/
   ```

2. **Install Docker** (required for container deployments):
   ```bash
   # macOS
   brew install docker
   
   # Linux/Windows - see https://docs.docker.com/get-docker/
   ```

3. **Install AWS CLI** and **configure AWS credentials**:

   **Option A: AWS CLI Configuration (Quick Start)**
   ```bash
   aws configure
   # Enter your AWS Access Key ID, Secret Key, and region (e.g., us-east-1)
   ```

   To create access keys:
   1. Sign in to AWS Console → IAM → Users → Your username
   2. Security credentials tab → Access keys → Create access key
   3. Select "Command Line Interface (CLI)"
   4. Download the credentials (you won't see the secret key again!)

   > ⚠️ **Security Note**: Access keys are convenient but not the most secure option. For production use, consider:
   > - IAM roles (for EC2/Lambda)
   > - AWS SSO/Identity Center
   > - Temporary credentials with `aws sts assume-role`
   > - AWS Vault for local credential management

## Quick Start

### Step 1: Bootstrap the Backend (One-time setup)

This creates the S3 bucket and DynamoDB table for storing Terraform state:

```bash
cd deploy/aws/bootstrap/terraform
tofu init
tofu apply
# Type 'yes' when prompted
```

This creates a `backend-config.hcl` file with your S3 bucket details.

If it doesn't get created, just touch one in the root of your directory that looks like this (you get the values when apply is run in bootstrap):

```terraform
bucket         = "terraform-state-myAccountId-randomShaHash"
key            = "CHANGE_ME/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-state-locks"
encrypt        = true
```
### Step 2: Deploy Your Infrastructure

Now you can deploy any service. Let's start with the Lambda example:

```bash
# Navigate to the Lambda deployment
cd deploy/preview/lambda

# Initialize Terraform with the backend config
# The ../../../backend-config.hcl path always points to your root directory
tofu init -backend-config=../../../backend-config.hcl

# Review what will be created
tofu plan

# Create the infrastructure (type 'yes' when prompted)
tofu apply
```

💡 **First time using Terraform?** 
- `init` downloads providers and configures state storage
- `plan` shows what will be created without making changes
- `apply` actually creates the AWS resources

📁 **Path structure**: All deployments follow `deploy/{environment}/{service}/`, so the backend config is always 4 levels up (`../../../../`)

## Choosing Between Lambda, ECS Fargate, and ECS EC2

### AWS Lambda
**Best for:**
- Event-driven workloads (API Gateway, S3 events, SQS)
- Infrequent or unpredictable traffic
- Simple microservices under 15 minutes execution time
- Rapid scaling from 0 to thousands of concurrent executions

**Example use cases:**
- REST APIs with sporadic traffic
- Image/file processing triggered by S3 uploads
- Scheduled jobs (cron-like tasks)
- Webhooks and event handlers

**Limitations:**
- 15-minute maximum execution time
- 10GB memory limit
- 512MB temporary storage
- Cold starts can impact latency

### ECS Fargate
**Best for:**
- Long-running services
- Predictable workloads
- When you need full control over the runtime
- Applications requiring more than Lambda's limits

**Example use cases:**
- Web applications with consistent traffic
- Background job processors
- Microservices that need persistent connections
- Applications requiring specific runtime configurations

**Benefits:**
- No server management
- Pay per task
- Scales automatically
- Supports any containerized workload

### ECS EC2
**Best for:**
- Cost optimization at scale
- GPU or specialized compute requirements
- When you need maximum control over the infrastructure
- High-memory or high-CPU applications

**Example use cases:**
- Large-scale web applications
- Machine learning inference
- High-performance databases
- Applications requiring local NVMe storage

**Trade-offs:**
- Must manage EC2 instances
- More complex scaling
- Better cost efficiency at scale
- Full control over instance types

## End-to-End Examples

### Deploy Lambda Function

```bash
cd deploy/aws/preview/lambda
tofu init -backend-config=../../../../backend-config.hcl
tofu plan
tofu apply
```

That's it! Everything is created in one go:
- ECR repository
- Docker image built and pushed
- Lambda function with the container
- API endpoint with authentication

Test it:
```bash
curl -H "X-API-Key: $(tofu output -raw api_key)" $(tofu output -raw lambda_function_url)
```

View logs:
```bash
aws logs tail $(tofu output -raw log_group_name) --follow --region us-east-1
```

### Deploy ECS Fargate

```bash
cd deploy/aws/preview/ecs-fargate
tofu init -backend-config=../../../../backend-config.hcl
tofu plan
tofu apply
```

Creates everything automatically:
- VPC with subnets
- ECR repository
- Docker image built and pushed
- ECS cluster and service
- Application Load Balancer with public access
- Security groups

Test the API:
```bash
# Health check (no auth required)
curl $(tofu output -raw api_url)/health

# API with authentication
curl -H "X-API-Key: $(tofu output -raw api_key)" $(tofu output -raw api_url)
```

View logs:
```bash
aws logs tail $(tofu output -raw log_group_name) --follow --region us-east-1
```

### Deploy ECS EC2

```bash
cd deploy/aws/preview/ecs-ec2
tofu init -backend-config=../../../../backend-config.hcl
tofu plan
tofu apply
```

Creates everything automatically:
- VPC with subnets
- ECR repository
- Docker image built and pushed
- ECS cluster with Auto Scaling Group
- EC2 instances with ECS agent
- Application Load Balancer with public access
- Security groups

Test the API:
```bash
# Health check (no auth required)
curl $(tofu output -raw api_url)/health

# API with authentication
curl -H "X-API-Key: $(tofu output -raw api_key)" $(tofu output -raw api_url)
```

View logs:
```bash
aws logs tail $(tofu output -raw log_group_name) --follow --region us-east-1
```

## Common Operations

### Viewing Logs

All services send logs to CloudWatch automatically:

```bash
# Lambda logs
aws logs tail /aws/lambda/{function-name} --follow --region us-east-1

# ECS logs (Fargate or EC2)
aws logs tail /ecs/{cluster-name}/{service-name} --follow --region us-east-1

# Search for errors in the last hour
aws logs filter-log-events \
  --log-group-name /aws/lambda/{function-name} \
  --filter-pattern "ERROR" \
  --start-time $(date -u -d '1 hour ago' +%s)000 \
  --region us-east-1
```

### Updating Container Images

Since all deployments build and push images automatically:

```bash
# Make changes to your code in docker/rest-server/
# Then just run:
tofu apply

# Terraform will rebuild, push, and update the service
```

### Debugging Containers

For ECS services with execute command enabled:

```bash
# List running tasks
aws ecs list-tasks --cluster {cluster-name} --region us-east-1

# Connect to a container
aws ecs execute-command \
  --cluster {cluster-name} \
  --task {task-arn} \
  --container rest-api \
  --interactive \
  --command "/bin/sh" \
  --region us-east-1

# Without API key returns 401
curl $FUNCTION_URL
```

💡 **Tip**: Save your API key somewhere safe - you can always retrieve it later with `tofu output -raw api_key`

### Cleanup

To remove all resources:

```bash
cd deploy/preview/lambda
tofu destroy
```

## Features

- 🏗️ **Pure Terraform** - No shell scripts, fully declarative
- 🔒 **Remote State** - S3 backend with DynamoDB locking
- 🔑 **Automatic Backend Config** - No manual key management needed
- 📦 **Modular Design** - Reusable modules in `lib/terraform/`
- 🧪 **Testing Built-in** - Terratest framework included
- 🎯 **Type Safety** - Validation through Terraform patterns
- 📁 **Organized Structure** - Environment/service based deployments

## Project Structure

```
├── bootstrap/          # Backend infrastructure setup
├── lib/terraform/      # Reusable Terraform modules
├── deploy/            # Environment deployments
│   ├── preview/
│   ├── staging/
│   └── production/
└── tests/             # Module tests
```

## Useful Commands

```bash
# Working with deployments - navigate to the deployment directory first
cd deploy/preview/lambda

# Initialize a deployment
tofu init -backend-config=../../../backend-config.hcl

# Preview changes
tofu plan

# Apply changes
tofu apply

# Destroy infrastructure
tofu destroy

# Development helpers
tofu fmt -recursive       # Format all Terraform files
tofu validate            # Validate configuration
go test ./tests/...      # Run module tests (requires Go)
```

## Creating New Deployments

1. **Create your deployment directory** (always use the pattern `deploy/{environment}/{service}`):
   ```bash
   mkdir -p deploy/preview/my-service
   ```

2. **Copy an existing deployment as a template**:
   ```bash
   cp -r deploy/preview/lambda/* deploy/preview/my-service/
   ```

3. **Update the backend key** in `main.tf` to match your path:
   ```hcl
   backend "s3" {
     key = "preview/my-service/terraform.tfstate"  # Matches your directory path
   }
   ```

4. **Initialize and deploy**:
   ```bash
   cd deploy/preview/my-service
   tofu init -backend-config=../../../backend-config.hcl
   tofu apply
   ```

🎯 **Key point**: The backend config path is always `../../../backend-config.hcl` because all deployments are exactly 3 directories deep


## Requirements

- **OpenTofu** or Terraform >= 1.5.0 ([Install OpenTofu](https://opentofu.org/docs/intro/install/))
- **AWS CLI** configured with credentials ([Install AWS CLI](https://aws.amazon.com/cli/))
- **Docker** for building and pushing container images ([Install Docker](https://docs.docker.com/get-docker/))
- **Go** (for testing - optional) ([Install Go](https://golang.org/doc/install))
- **TFLint** (optional) ([Install TFLint](https://github.com/terraform-linters/tflint))
- **terraform-docs** (optional) ([Install terraform-docs](https://terraform-docs.io/user-guide/installation/))

## Testing

The project includes automated tests using Terratest (Go-based testing framework for infrastructure).

### Running Tests

```bash
cd tests
go mod download
go test -v -timeout 30m
```

**Note**: Tests create real AWS resources and incur costs. Run them in a test account.

### Test Structure

- `tests/` - Test files using Terratest
- `test-fixtures/` - Minimal Terraform configurations for testing modules

Example test output:
```
=== RUN   TestECRRepository
=== RUN   TestLambdaContainer
--- PASS: TestECRRepository (45.2s)
--- PASS: TestLambdaContainer (52.1s)
PASS
```

## Contributing

1. Create modules in `lib/terraform/`
2. Write tests in `tests/`
3. Follow the established patterns
4. Run `tofu validate` and `tofu fmt -recursive` before committing

## License

MIT
