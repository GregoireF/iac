# Unit tests: `opa test policies/opentofu -v`.
package main

import rego.v1

repo_addr := "module.repos[\"demo\"].github_repository.this"

alerts_addr := "module.repos[\"demo\"].github_repository_vulnerability_alerts.this[0]"

repo(actions, after) := {
	"address": repo_addr,
	"type": "github_repository",
	"change": {"actions": actions, "after": after},
}

alerts(actions, enabled) := {
	"address": alerts_addr,
	"type": "github_repository_vulnerability_alerts",
	"change": {"actions": actions, "after": {"enabled": enabled}},
}

public := {"visibility": "public", "archived": false}

test_update_with_alerts_ok if {
	count(deny) == 0 with input as {"resource_changes": [repo(["update"], public), alerts(["no-op"], true)]}
}

test_delete_denied if {
	count(deny) == 1 with input as {"resource_changes": [repo(["delete"], null)]}
}

test_replace_denied if {
	count(deny) == 1 with input as {"resource_changes": [repo(["delete", "create"], public), alerts(["create"], true)]}
}

test_public_without_alerts_denied if {
	count(deny) == 1 with input as {"resource_changes": [repo(["update"], public)]}
}

test_public_with_disabled_alerts_denied if {
	count(deny) == 1 with input as {"resource_changes": [repo(["update"], public), alerts(["update"], false)]}
}

test_alerts_being_deleted_denied if {
	count(deny) == 1 with input as {"resource_changes": [repo(["update"], public), alerts(["delete"], true)]}
}

test_archived_public_without_alerts_allowed if {
	count(deny) == 0 with input as {"resource_changes": [repo(["update"], {"visibility": "public", "archived": true})]}
}

test_other_destroy_warns if {
	count(warn) == 1 with input as {"resource_changes": [{
		"address": "github_issue_label.old",
		"type": "github_issue_label",
		"change": {"actions": ["delete"], "after": null},
	}]}
}
