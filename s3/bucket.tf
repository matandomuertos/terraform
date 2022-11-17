resource "aws_s3_bucket" "test123987" {
  bucket_prefix = var.bucket_prefix
  tags          = var.tags
}

resource "aws_s3_bucket_versioning" "versioning_test123987" {
  bucket = aws_s3_bucket.test123987.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_acl" "acl_test123987" {
  bucket = aws_s3_bucket.test123987.id
  acl    = var.acl
}
