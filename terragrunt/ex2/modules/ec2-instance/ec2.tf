resource "aws_instance" "test-ec2-instance" {
  ami = var.ami
  instance_type = var.instance_type  
  subnet_id = var.subnetid

  tags = {
    Name = var.instance_name
  }
}
