import {
  id = "iac"
  to = module.repository["iac"].github_repository.this
}

import {
  id = "utils"
  to = module.repository["utils"].github_repository.this
}

import {
  id = "GregoireF"
  to = module.repository["GregoireF"].github_repository.this
}

import {
  id = "notiftk"
  to = module.repository["notiftk"].github_repository.this
}

# GitHub creates these labels with every new repository: import them into the
# standard set instead of creating them again (422 already_exists).

import {
  id = "ship-it-sandbox:bug"
  to = github_issue_label.standard["ship-it-sandbox:bug"]
}

import {
  id = "ship-it-sandbox:documentation"
  to = github_issue_label.standard["ship-it-sandbox:documentation"]
}

import {
  id = "ship-it-sandbox:enhancement"
  to = github_issue_label.standard["ship-it-sandbox:enhancement"]
}

import {
  id = "ship-it-sandbox:question"
  to = github_issue_label.standard["ship-it-sandbox:question"]
}
