resource "aws_db_subnet_group" "test-subnet-group" {
  subnet_ids = var.subnetids
}

resource "aws_db_instance" "test-rds-instance" {
  allocated_storage = var.allocated_storage
  storage_type = var.storage_type
  engine = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class
  db_name = var.db_name
  username = var.username
  password = var.password
  publicly_accessible = var.publicly_accessible
  skip_final_snapshot = var.skip_final_snapshot
  db_subnet_group_name = aws_db_subnet_group.test-subnet-group.id
  tags = {
    Name = var.rds_name
  }
}