# Terraform Module Tests

This directory contains automated tests for the Terraform modules using Terratest.

## Prerequisites

- Go 1.21 or later
- AWS credentials configured
- OpenTofu/Terraform installed

## Running Tests

```bash
# Download dependencies
go mod download

# Run all tests
go test -v -timeout 30m

# Run a specific test
go test -v -run TestECRRepository -timeout 30m
```

## Test Structure

- `*_test.go` - Test files for each module
- `test-fixtures/` - Minimal Terraform configurations used by tests

## What the Tests Do

1. Deploy real infrastructure to AWS
2. Validate the infrastructure was created correctly
3. Clean up all resources after testing

⚠️ **Warning**: These tests create real AWS resources that cost money. Always run in a test account.