Deploy EKS using terragrunt, based on google and background experience, for sure it's not the best way but it's a way.

- (Terraform EKS Cluster documentation)[https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster]

# Disclaimer
Hello Nahuel from the future, this is a message from the past. This code is working but not working-working, it's ok as a guide but not to deploy to production, there are missing resources, hardcoded values and it wasn't fully tested because I'm lazy.
One more thing, I hope you are already millionaire and you are here just for fun because in some moment I've stopped to document what I was doing so... Good luck!

## Another message from the past
I think that use terraground doesn't have much sense, it's easier to simply use multiple `terraform.tfvars`. But yeah, for sure I know less than you so maybe our opinion has changed.