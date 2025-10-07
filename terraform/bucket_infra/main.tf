module "object_storage" {
  source      = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/s3_bucket/vpc_flow_log_s3?ref=v1.2.5"
  bucket_name = "${local.bucket}-vpc"
  tags = merge(local.s3_tags, {
    Name = "${local.name}-s3-bucket"
  })
}

module "etl_storage" {
  source      = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/s3_bucket/storage?ref=v1.4.0"
  bucket_name = "${local.bucket}-etl"
  tags = merge(local.s3_tags, {
    Name = "${local.name}-s3-bucket"
  })
}

module "airflow_storage" {
  source      = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/s3_bucket/storage?ref=v1.4.0"
  bucket_name = "${local.bucket}-airflow"
  tags = merge(local.s3_tags, {
    Name = "${local.name}-s3-bucket"
  })
}