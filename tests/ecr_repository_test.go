package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestECRRepository tests the ECR repository module
func TestECRRepository(t *testing.T) {
	t.Parallel()

	// Generate a unique name for the test
	uniqueID := strings.ToLower(random.UniqueId())
	repositoryName := fmt.Sprintf("test-repo-%s", uniqueID)
	awsRegion := "us-east-1"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../test-fixtures/ecr-repository",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"repository_name": repositoryName,
			"aws_region":      awsRegion,
		},

		// Environment variables to set when running Terraform
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` and `terraform apply`. Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the values of output variables
	repositoryURL := terraform.Output(t, terraformOptions, "repository_url")
	repositoryARN := terraform.Output(t, terraformOptions, "repository_arn")
	repositoryNameOutput := terraform.Output(t, terraformOptions, "repository_name")

	// Verify the repository was created with the expected values
	assert.Equal(t, repositoryName, repositoryNameOutput)
	assert.Contains(t, repositoryURL, repositoryName)
	assert.Contains(t, repositoryARN, fmt.Sprintf("repository/%s", repositoryName))

	// Verify the repository exists in AWS
	aws.GetECRRepo(t, awsRegion, repositoryName)
}

// TestLambdaContainer tests the Lambda container module with a minimal configuration
func TestLambdaContainer(t *testing.T) {
	t.Parallel()

	// Generate a unique name for the test
	uniqueID := strings.ToLower(random.UniqueId())
	functionName := fmt.Sprintf("test-lambda-%s", uniqueID)
	awsRegion := "us-east-1"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../test-fixtures/lambda-container",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"function_name": functionName,
			"aws_region":    awsRegion,
		},

		// Environment variables to set when running Terraform
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// Run `terraform init` and `terraform apply`. Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the values of output variables
	functionNameOutput := terraform.Output(t, terraformOptions, "function_name")
	functionARN := terraform.Output(t, terraformOptions, "function_arn")
	roleARN := terraform.Output(t, terraformOptions, "role_arn")

	// Verify outputs
	assert.Equal(t, functionName, functionNameOutput)
	assert.Contains(t, functionARN, functionName)
	assert.Contains(t, roleARN, "arn:aws:iam::")

	// Verify the Lambda function exists in AWS
	// We can invoke it or just check that terraform created it successfully
	// For now, the successful terraform apply and correct outputs are sufficient validation
}