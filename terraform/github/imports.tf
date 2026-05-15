# Import blocks for pre-existing repositories.
# Run once: terraform plan will show the import, terraform apply will absorb the resource.
# After a successful apply, these blocks can be removed (the resource is now tracked in state).

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
