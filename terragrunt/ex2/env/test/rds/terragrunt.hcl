# Automatically find the root terragrunt.hcl and inherit its
# configuration
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/rds-instance"
}

inputs = {
  subnetids = ["subnet-08efc43bb161ed3b0", "subnet-072f510a3184e429a"]
  rds_name = "example-rds-test"
  username = "root"
  password = "abcd1234" #yeah, this is wrong
}
