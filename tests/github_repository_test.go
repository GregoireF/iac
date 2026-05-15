// Integration tests for modules/github/repository.
// These tests create REAL GitHub resources and destroy them after.
// They require a GitHub token with repo creation permissions.
//
// Run locally:
//   export GITHUB_TOKEN=<your-token>
//   export GITHUB_OWNER=<your-username>
//   cd tests && go test -v -run TestGitHubRepository -timeout 10m
//
// Skipped automatically when GITHUB_TOKEN is not set.
package test

import (
	"fmt"
	"math/rand"
	"os"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func randomSuffix() string {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	return fmt.Sprintf("%06d", r.Intn(999999))
}

func skipIfNoCredentials(t *testing.T) {
	t.Helper()
	if os.Getenv("GITHUB_TOKEN") == "" {
		t.Skip("Skipping integration test: GITHUB_TOKEN not set")
	}
	if os.Getenv("GITHUB_OWNER") == "" {
		t.Skip("Skipping integration test: GITHUB_OWNER not set")
	}
}

func TestGitHubRepositoryModule(t *testing.T) {
	t.Parallel()
	skipIfNoCredentials(t)

	repoName := fmt.Sprintf("terratest-%s", randomSuffix())
	owner := os.Getenv("GITHUB_OWNER")

	opts := &terraform.Options{
		TerraformDir: "../modules/github/repository",
		Vars: map[string]interface{}{
			"owner": owner,
			"name":  repoName,
			"config": map[string]interface{}{
				"description":            "Terratest integration test repository — safe to delete",
				"topics":                 []string{"terratest", "test"},
				"visibility":             "public",
				"has_issues":             true,
				"has_wiki":               false,
				"has_projects":           false,
				"allow_merge_commit":     false,
				"allow_squash_merge":     true,
				"allow_rebase_merge":     false,
				"delete_branch_on_merge": true,
				"archived":               false,
				"inject_standard_files":  false,
				"allow_auto_merge":       false,
				"branch_protection": map[string]interface{}{
					"enabled":                false,
					"required_status_checks": []string{},
				},
				"environments": map[string]interface{}{},
				"deploy_keys":  map[string]interface{}{},
			},
		},
		EnvVars: map[string]string{
			"GITHUB_TOKEN": os.Getenv("GITHUB_TOKEN"),
			"GITHUB_OWNER": owner,
		},
		NoColor: true,
	}

	// Destroy the test repo when the test finishes (pass or fail).
	defer terraform.Destroy(t, opts)

	terraform.InitAndApply(t, opts)

	t.Run("name matches input", func(t *testing.T) {
		actual := terraform.Output(t, opts, "name")
		assert.Equal(t, repoName, actual)
	})

	t.Run("html_url contains owner and name", func(t *testing.T) {
		url := terraform.Output(t, opts, "html_url")
		assert.Contains(t, url, owner)
		assert.Contains(t, url, repoName)
	})

	t.Run("ssh_clone_url is set", func(t *testing.T) {
		sshURL := terraform.Output(t, opts, "ssh_clone_url")
		require.NotEmpty(t, sshURL)
		assert.Contains(t, sshURL, repoName)
	})
}

func TestGitHubRepositoryBranchProtection(t *testing.T) {
	t.Parallel()
	skipIfNoCredentials(t)

	repoName := fmt.Sprintf("terratest-bp-%s", randomSuffix())
	owner := os.Getenv("GITHUB_OWNER")

	opts := &terraform.Options{
		TerraformDir: "../modules/github/repository",
		Vars: map[string]interface{}{
			"owner": owner,
			"name":  repoName,
			"config": map[string]interface{}{
				"description":            "Terratest branch protection test — safe to delete",
				"topics":                 []string{"terratest"},
				"visibility":             "public",
				"has_issues":             false,
				"has_wiki":               false,
				"has_projects":           false,
				"allow_merge_commit":     false,
				"allow_squash_merge":     true,
				"allow_rebase_merge":     false,
				"delete_branch_on_merge": true,
				"archived":               false,
				"inject_standard_files":  false,
				"allow_auto_merge":       false,
				"branch_protection": map[string]interface{}{
					"enabled":                true,
					"required_status_checks": []string{},
				},
				"environments": map[string]interface{}{},
				"deploy_keys":  map[string]interface{}{},
			},
		},
		EnvVars: map[string]string{
			"GITHUB_TOKEN": os.Getenv("GITHUB_TOKEN"),
			"GITHUB_OWNER": owner,
		},
		NoColor: true,
	}

	defer terraform.Destroy(t, opts)
	terraform.InitAndApply(t, opts)

	t.Run("repository created successfully", func(t *testing.T) {
		name := terraform.Output(t, opts, "name")
		assert.Equal(t, repoName, name)
	})
}
