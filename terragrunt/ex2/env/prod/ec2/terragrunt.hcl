# Automatically find the root terragrunt.hcl and inherit its
# configuration
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/ec2-instance"
}

inputs = {
  instance_type = "t2.small"
  instance_name = "example-server-prod"
  subnetid = "subnet-08efc43bb161ed3b0"
}
