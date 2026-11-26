# GitHub creates these labels with every new repository: import them into the
# standard set instead of creating them again (422 already_exists). Remove the
# blocks once applied, as for ship-it (#38, 90037ad).

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
