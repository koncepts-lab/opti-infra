resource_group_name  = "terraform-state-rg"
storage_account_name = "oiitfstatetest"   # Note: test specific
container_name      = "tfstate"
key                 = "test.terraform.tfstate"  # Note: test specific
use_azuread_auth    = true
subscription_id     = "cbae65ed-46b5-4899-8f50-0a64777cbfea"
tenant_id          = "3970c661-584d-4ad9-9a2b-60f2878efac7"