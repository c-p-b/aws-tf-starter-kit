package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformLambdaFunction(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../test-fixtures/lambda-function",
		Vars: map[string]interface{}{
			"function_name": "test-lambda-" + RandomString(6),
			"environment":   "test",
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify outputs
	functionName := terraform.Output(t, terraformOptions, "function_name")
	functionArn := terraform.Output(t, terraformOptions, "function_arn")
	roleArn := terraform.Output(t, terraformOptions, "role_arn")

	assert.NotEmpty(t, functionName)
	assert.Contains(t, functionName, "test-lambda-")
	assert.Contains(t, functionArn, "arn:aws:lambda:")
	assert.Contains(t, roleArn, "arn:aws:iam:")
}