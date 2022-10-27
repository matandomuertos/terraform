Basic ec2 instance + RDS deployed by terragrunt, mainly based on https://blog.gruntwork.io/how-to-manage-multiple-environments-with-terraform-using-terragrunt-2c3e32fc60a8#e777 and a little of google

This example generates a single point for provider configuration, just run `terragrunt run-all apply` from the main folder of the environment you want to deploy and that's all.