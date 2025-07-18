# AWS Terraform Starter Kit - Technical Documentation

## Architecture Overview

This starter kit implements a pure Terraform/OpenTofu infrastructure-as-code pattern with:

1. **Bootstrap Module** - Sets up S3 backend and DynamoDB state locking
2. **Reusable Modules** - Located in `lib/terraform/`
3. **Deployment Structure** - Organized by environment and service
4. **Testing Framework** - Terratest for module validation

## Project Structure

```
.
├── bootstrap/           # Backend infrastructure setup
├── lib/terraform/       # Reusable Terraform modules
├── deploy/             # Environment-specific deployments
│   ├── preview/        # Preview environment
│   ├── staging/        # Staging environment  
│   └── production/     # Production environment
└── tests/              # Terratest module tests
```

## Key Design Decisions

### 1. Pure Declarative Approach
- No shell scripts for infrastructure management
- All configuration through Terraform modules
- Validation through Terraform provider patterns

### 2. Module Composition Pattern
Every deployment uses:
- `deployment-base` module for common configuration
- Service-specific modules from `lib/terraform/`
- Consistent tagging and naming conventions

### 3. Backend State Management
- Bootstrap creates S3 bucket and DynamoDB table
- State keys follow pattern: `{environment}/{service}/terraform.tfstate`
- Encryption enabled by default

### 4. Type Safety Through Modules
- `deployment-base` enforces environment/service validation
- `deployment-validator` provides additional checks
- Module interfaces define clear contracts

## Common Workflows

### Initial Setup
```bash
cd bootstrap/terraform
tofu init
tofu apply
# Note the outputs for backend configuration
```

### Creating New Deployment
1. Create directory: `deploy/{environment}/{service}/`
2. Copy structure from existing deployment
3. Update backend configuration with bootstrap outputs
4. Customize for your service

### Module Development
1. Create module in `lib/terraform/{module-name}/`
2. Required files:
   - `main.tf` - Main module logic
   - `inputs.tf` - Variable declarations
   - `output.tf` - Output values
3. Do NOT include `versions.tf` - version constraints belong only in root deployments
4. Add test in `tests/`
5. Document with terraform-docs

## Testing Strategy

- **Unit Tests**: Terratest for individual modules
- **Validation**: TFLint for syntax and best practices
- **Documentation**: terraform-docs for auto-generated docs

## Conventions

### Naming
- Resources: `{project}-{environment}-{service}-{resource}`
- Modules: Descriptive, hyphenated names
- Variables: Snake_case

### Tagging
All resources tagged with:
- Environment
- Service
- Project
- ManagedBy (always "terraform")

### File Structure
Each deployment must have:
- `main.tf` - Backend config, provider requirements, and module calls
- `providers.tf` - Provider configuration
- `variables.tf` - Input variables (optional)
- `outputs.tf` - Output values (optional)

Modules should have:
- `main.tf` - Module implementation
- `inputs.tf` - Variable declarations (not variables.tf)
- `output.tf` - Output values (not outputs.tf)
- NO `versions.tf` - Version constraints only in deployments

## Commands Reference

```bash
make help                           # Show available commands
make init DEPLOY_DIR=deploy/preview/lambda    # Initialize deployment
make plan DEPLOY_DIR=deploy/preview/lambda    # Plan changes
make apply DEPLOY_DIR=deploy/preview/lambda   # Apply changes
make fmt                           # Format all files
make lint                          # Run linting
make test                          # Run tests
make docs                          # Generate documentation
```

## Container Deployments

All services use container images stored in ECR:

### Lambda Container
- Uses AWS Lambda container runtime
- REST API endpoint support
- Automatic scaling

### ECS Fargate
- Serverless container hosting
- Network isolation
- Pay per use

### ECS EC2
- Container hosting on EC2 instances
- Better for consistent workloads
- More control over infrastructure

### Building and Pushing Images

```bash
# Build Lambda image
docker build -t rest-server:lambda -f docker/rest-server/Dockerfile docker/rest-server/

# Build ECS image
docker build -t rest-server:ecs -f docker/rest-server/Dockerfile.ecs docker/rest-server/

# Tag and push to ECR (after terraform apply)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL
docker tag rest-server:lambda $ECR_URL:latest
docker push $ECR_URL:latest
```

## Module Interfaces

### deployment-base
Provides common configuration for all deployments:
- Standardized tagging
- Environment/service validation
- Naming conventions

### lambda-container
Creates containerized Lambda with:
- IAM role and policies
- CloudWatch logs
- Optional VPC configuration
- Container image support

### ecr-repository
Creates ECR repository with:
- Encryption enabled
- Image scanning
- Lifecycle policies
- Repository policies

### ecs-cluster
Creates ECS cluster with:
- Container Insights
- Capacity providers (Fargate/EC2)
- Default capacity provider strategies

### ecs-service
Creates ECS service supporting:
- Both Fargate and EC2 launch types
- Task definitions with container configurations
- Security groups and networking
- Load balancer integration
- Service discovery
- CloudWatch logging

## Best Practices

1. **Always use modules** - Don't create resources directly in deployments
2. **Test modules** - Write Terratest for new modules
3. **Document outputs** - Clear descriptions for module outputs
4. **Version constraints** - Pin provider and module versions
5. **State isolation** - Separate state per environment/service

## Monitoring and Logging

### Viewing CloudWatch Logs

All containerized services (Lambda, ECS) automatically send logs to CloudWatch. To view logs:

```bash
# Tail Lambda logs in real-time
aws logs tail /aws/lambda/{function-name} --follow --region us-east-1

# View last 5 minutes of logs
aws logs tail /aws/lambda/{function-name} --since 5m --region us-east-1

# Search for errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/{function-name} \
  --filter-pattern "ERROR" \
  --region us-east-1

# View ECS logs
aws logs tail /ecs/{cluster-name}/{service-name} --follow --region us-east-1
```

Log retention is set to 7 days by default for all services.

## Troubleshooting

### Backend Configuration
If backend not configured:
1. Run bootstrap first
2. Copy backend config from bootstrap outputs
3. Update key to match your deployment path

### Module Not Found
Ensure relative paths are correct:
- From deploy: `../../../lib/terraform/module-name`
- Use `path.module` for file references

### Validation Errors
Check:
- Environment is one of: preview, staging, production
- Service follows naming convention
- Backend key matches pattern