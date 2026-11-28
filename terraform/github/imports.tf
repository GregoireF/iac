# GitHub creates these labels with every new repository: import them into the
# standard set instead of creating them again (422 already_exists). Remove the
# blocks once applied, as for ship-it (#38, 90037ad).

# kiwa's CODE_SCANNING was set by hand on 2026-11-14 (actions-config.tf).
import {
  id = "kiwa:CODE_SCANNING"
  to = github_actions_variable.kiwa_code_scanning
}

import {
  id = "telly:bug"
  to = github_issue_label.standard["telly:bug"]
}

import {
  id = "telly:documentation"
  to = github_issue_label.standard["telly:documentation"]
}

import {
  id = "telly:enhancement"
  to = github_issue_label.standard["telly:enhancement"]
}

import {
  id = "telly:question"
  to = github_issue_label.standard["telly:question"]
}
