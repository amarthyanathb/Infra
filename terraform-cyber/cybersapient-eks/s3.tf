module "s3_bucket_opsverse" {
  source = "../modules/s3"

  bucket_name = var.s3_bucket_name
  bucket_tags = {
    "Name" = var.s3_bucket_name
  }
}
