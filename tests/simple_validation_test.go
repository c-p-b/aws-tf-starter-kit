package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestModuleValidation validates that our Terraform modules have correct syntax
// This is a simple test that doesn't create actual resources
func TestModuleValidation(t *testing.T) {
	t.Parallel()

	// Test cases for different modules
	testCases := []struct {
		name         string
		terraformDir string
	}{
		{
			name:         "ECR Repository Module",
			terraformDir: "../lib/terraform/ecr-repository",
		},
		{
			name:         "Lambda Container Module",
			terraformDir: "../lib/terraform/lambda-container",
		},
		{
			name:         "ECS Cluster Module",
			terraformDir: "../lib/terraform/ecs-cluster",
		},
	}

	for _, tc := range testCases {
		// Capture tc variable for parallel tests
		tc := tc
		
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := &terraform.Options{
				TerraformDir: tc.terraformDir,
				
				// Don't actually apply, just init and validate
				PlanFilePath: "/tmp/tfplan",
			}

			// Run terraform init
			terraform.Init(t, terraformOptions)
			
			// Run terraform validate to check syntax
			terraform.Validate(t, terraformOptions)
			
			// If we get here, the module is syntactically valid
			assert.True(t, true, "Module %s passed validation", tc.name)
		})
	}
}