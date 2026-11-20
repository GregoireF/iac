# Policies evaluated by Conftest on the JSON plan (`tofu show -json plan.out > plan.json`).
# https://www.conftest.dev/ — Rego v1 syntax (OPA 1.x).
# They are an independent safety net: they still hold if a module loses its own protections.
package main

import rego.v1

repo_changes contains rc if {
	some rc in input.resource_changes
	rc.type == "github_repository"
}

# Address of the vulnerability-alerts resource that must sit next to a repository in the same module.
alerts_address(repo_address) := concat("", [trim_suffix(repo_address, "github_repository.this"), "github_repository_vulnerability_alerts.this[0]"])

alerts_enabled contains rc.address if {
	some rc in input.resource_changes
	rc.type == "github_repository_vulnerability_alerts"
	not "delete" in rc.change.actions
	rc.change.after.enabled == true
}

# A repository is never destroyed by automation: archive it instead.
deny contains msg if {
	some rc in repo_changes
	"delete" in rc.change.actions
	msg := sprintf("%s would be DELETED: archive the repository instead (archived = true)", [rc.address])
}

# Every public, non-archived repository keeps Dependabot vulnerability alerts on
# (resource github_repository_vulnerability_alerts, provider >= 6.12).
deny contains msg if {
	some rc in repo_changes
	after := rc.change.after
	after.visibility == "public"
	not after.archived
	not alerts_address(rc.address) in alerts_enabled
	msg := sprintf("%s is public without enabled vulnerability alerts (%s)", [rc.address, alerts_address(rc.address)])
}

# Any destroy elsewhere is surfaced in the PR (warning, not blocking).
warn contains msg if {
	some rc in input.resource_changes
	rc.type != "github_repository"
	"delete" in rc.change.actions
	msg := sprintf("%s will be destroyed", [rc.address])
}
