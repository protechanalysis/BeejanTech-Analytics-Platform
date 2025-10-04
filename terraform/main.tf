module "object_storage" {
  source      = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/s3_bucket/vpc_flow_log_s3?ref=v1.2.5"
  bucket_name = "${local.bucket}-vpc-flow-logs"
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

module "bootstrap_scripts_upload" {
  source     = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/s3_upload?ref=v1.4.5"
  bucket     = module.airflow_storage.cloud_beejan_bucket_name
  source_dir = "../bootstrap_scripts"
  prefix     = "bootstrap_scripts/"
}

module "vpc" {
  source          = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/vpc?ref=v1.2.5"
  name            = "${local.name}-vpc"
  cidr_block      = "10.0.0.0/16"
  log_destination = module.object_storage.vpc_flow_logs_bucket_arn
  depends_on      = [module.object_storage, module.etl_storage, module.bootstrap_scripts_upload]
  tags            = local.vpc_tags
}

module "public_subnet" {
  source                  = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/subnets?ref=v1.2.5"
  vpc_id                  = module.vpc.vpc_id
  map_public_ip_on_launch = true
  subnets                 = local.public_subnets
  tags = merge(local.subnet_tags, {
    Tier = "Public"
  })
}

module "private_subnet" {
  source                  = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/subnets?ref=v1.2.5"
  vpc_id                  = module.vpc.vpc_id
  map_public_ip_on_launch = false
  subnets                 = local.private_subnets
  tags = merge(local.subnet_tags, {
    Tier = "Private"
  })
}

module "igw" {
  source = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/internet_gateway?ref=v1.2.5"
  vpc_id = module.vpc.vpc_id
  tags = merge(local.common_tags, {
    Name = "${local.name}-vpc-igw"
    Type = "InternetGateway"
  })
}

# module "nat_gateway" {
#   source           = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/nat?ref=v1.2.5"
#   name             = "${local.name}-nat-gateway"
#   public_subnet_id = module.public_subnet.subnet_ids["public-1-a"]
#   tags = merge(local.common_tags, {
#     Name = "${local.name}-nat-gateway"
#     Type = "NATGateway"
#   })
# }

module "public_route_table" {
  source     = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/routes_tables?ref=v1.2.5"
  vpc_id     = module.vpc.vpc_id
  name       = "public-rt"
  type       = "public"
  route_cidr = local.allowed_cidr_blocks
  gateway_id = module.igw.igw_id
  subnet_ids = module.public_subnet.subnet_ids
  tags = merge(local.common_tags, {
    Name = "${local.name}-public-rt"
    Type = "Public"
  })
}

# module "private_route_table" {
#   source     = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/routes_tables?ref=v1.2.5"
#   vpc_id     = module.vpc.vpc_id
#   name       = "private-rt"
#   type       = "private"
#   route_cidr = local.allowed_cidr_blocks
#   nat_id     = module.nat_gateway.nat_id
#   subnet_ids = module.private_subnet.subnet_ids
#   tags = merge(local.common_tags, {
#     Name = "${local.name}-private-rt"
#     Type = "Private"
#   })
# }

module "instance_security_group" {
  source      = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/security_group?ref=v1.2.5"
  name        = "${local.name}-instance-sg"
  description = "Security group for EC2 instance"
  vpc_id      = module.vpc.vpc_id
  # depends_on  = [module.alb_security_group]

  ingress_rules = [
    {
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      source_security_group_id = module.alb_security_group.security_group_id
      description              = "Allow airflow access"
    },
    {
      from_port   = 8793
      to_port     = 8793
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
      description = "Allow worker log server communication (self-referencing)"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [local.allowed_cidr_blocks]
      description = "Allow SSH access"
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"] // Your VPC CIDR range
      description = "Allow outbound to RDS"
    }
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name}-instance-sg"
    Type = "SecurityGroup"
  })
}


module "database_security_group" {
  source      = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/security_group?ref=v1.2.5"
  name        = "${local.name}-database-sg"
  description = "Security group for RDS database"
  vpc_id      = module.vpc.vpc_id
  ingress_rules = [
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = module.instance_security_group.security_group_id
      description              = "Allow MySQL access from VPC"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name}-database-sg"
    Type = "SecurityGroup"
  })
}

module "alb_security_group" {
  source      = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/security_group?ref=v1.2.5"
  name        = "${local.name}-alb-sg"
  description = "Security group for alb"
  vpc_id      = module.vpc.vpc_id
  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [local.allowed_cidr_blocks]
      description = "Allow HTTP traffic"
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [local.allowed_cidr_blocks]
      description = "Allow all outbound traffic"
    }
  ]
  tags = merge(local.common_tags, {
    Name = "${local.name}-alb-sg"
    Type = "SecurityGroup"
  })
}

# module "random_password" {
#   source  = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/random_cred?ref=v1.3.7"
#   length  = 16
#   special = true
#   numeric = true
# }

# module "random_username" {
#   source = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/random_cred?ref=v1.3.7"
#   length = 10
# }

# module "rds" {
#   source                 = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/rds?ref=v1.3.5"
#   database_name          = "analyticsdb"
#   password               = module.random_password.result
#   username               = module.random_username.result
#   engine                 = "postgres"
#   engine_version         = "16.4"
#   parameter_group        = "default.postgres16"
#   instance_class         = "db.m5.large"
#   multi_az               = false
#   vpc_security_group_ids = [module.database_security_group.security_group_id]
#   subnet_id              = [module.private_subnet.subnet_ids["private-1-a"], module.private_subnet.subnet_ids["private-2-a"]]
#   depends_on             = [module.random_password, module.random_username]
#   tags = merge(local.rds_tags, {
#     Name = "${local.name}-rds-instance"
#   })
# }

# module "ec2_role" {
#   source               = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/iam_role/ec2_ssm_s3_redshift/?ref=v1.4.5"
#   name                 = "${local.name}-ec2"
#   bucket_names         = [module.airflow_storage.cloud_beejan_bucket_name, module.etl_storage.cloud_beejan_bucket_name]
#   redshift_cluster_ids = [module.redshift.redshift_cluster_id]
#   depends_on           = [module.redshift]
#   tags                 = local.ec2_tags
# }

# module "ec2_instance_1" {
#   source                  = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/instance?ref=v1.2.5"
#   instance_type           = "t3a.xlarge"
#   vpc_id                  = module.vpc.vpc_id
#   subnet_id               = module.public_subnet.subnet_ids["public-1-a"]
#   instance_profile_name   = module.ec2_role.instance_profile_name
#   key_pair                = local.key_name
#   security_group_id       = [module.instance_security_group.security_group_id]
#   ssh_allowed_cidr_blocks = [local.allowed_cidr_blocks]
#   assign_public_ip        = true
#   user_data               = file("../bootstrap_scripts/setup-run.sh")
#   depends_on              = [module.ssm_param]
#   tags = merge(local.ec2_tags, {
#     Name = "${local.name}-instance-1"
#   })
# }

# # module "ec2_instance_2" {
# #   source                  = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/instance?ref=v1.2.5"
# #   instance_type           = "t3a.xlarge"
# #   vpc_id                  = module.vpc.vpc_id
# #   subnet_id               = module.private_subnet.subnet_ids["private-2-a"]
# #   instance_profile_name   = module.ec2_role.instance_profile_name
# #   key_pair                = local.key_name
# #   security_group_id       = [module.instance_security_group.security_group_id]
# #   ssh_allowed_cidr_blocks = [local.allowed_cidr_blocks]
# #   user_data               = file("../bootstrap_scripts/setup-run.sh")
# #   depends_on              = [module.ssm_param]
# #   tags = merge(local.ec2_tags, {
# #     Name = "${local.name}-instance-2"
# #   })
# # }

# module "load_balancer" {
#   source       = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/load_balancer/application/?ref=v1.3.4"
#   vpc_id       = module.vpc.vpc_id
#   name         = "${local.name}-alb"
#   alb_sg_id    = [module.alb_security_group.security_group_id]
#   subnet_ids   = [module.public_subnet.subnet_ids["public-1-b"], module.public_subnet.subnet_ids["public-2-b"]]
#   instance_ids = { "instance_0" = module.ec2_instance_1.instance_id }
#   #   , "instance_1" = module.ec2_instance_2.instance_id }
#   enable_stickiness = true
#   cookie_duration   = 1800
#   health_check_path = "/api/v2/version"
#   listener_port     = 80
#   target_port       = 8080
#   protocol          = "HTTP"
#   tags = merge(local.common_tags, {
#     Name = "${local.name}-alb"
#     Type = "ApplicationLoadBalancer"
#   })
# }

# module "redshift_security_group" {
#   source      = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/security_group?ref=v1.2.5"
#   name        = "${local.name}-redshift-sg"
#   description = "Security group for redshift database"
#   vpc_id      = module.vpc.vpc_id
#   depends_on  = [module.instance_security_group]
#   ingress_rules = [
#     {
#       from_port                = 5439
#       to_port                  = 5439
#       protocol                 = "tcp"
#       source_security_group_id = module.instance_security_group.security_group_id
#       description              = "Allow MySQL access from VPC"
#     }
#   ]
#   egress_rules = [
#     {
#       from_port   = 0
#       to_port     = 0
#       protocol    = "-1"
#       cidr_blocks = [local.allowed_cidr_blocks]
#       description = "Allow all outbound traffic"
#     }
#   ]
#   tags = merge(local.common_tags, {
#     Name = "${local.name}-database-sg"
#     Type = "SecurityGroup"
#   })
# }

# module "redshift_role" {
#   source       = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/iam_role/redshift_s3_role?ref=v1.4.4"
#   bucket_names = [module.etl_storage.cloud_beejan_bucket_name]
#   name         = "${local.name}-redshift-role"
#   depends_on   = [module.random_password, module.random_username]
# }

# data "aws_ssm_parameter" "wh_password" {
#   name            = "dwh_password"
#   with_decryption = true
# }

# data "aws_ssm_parameter" "wh_username" {
#   name = "dwh_username"
# }

# data "aws_ssm_parameter" "wh_dbname" {
#   name = "dwh_database_name"
# }

# module "redshift" {
#   source                  = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/redshift?ref=v1.4.1"
#   name                    = "${local.name}-redshift-cluster"
#   database_name           = data.aws_ssm_parameter.wh_dbname.value
#   master_username         = data.aws_ssm_parameter.wh_username.value
#   master_password         = data.aws_ssm_parameter.wh_password.value
#   node                    = "ra3.large"
#   cluster                 = "single-node"
#   number_of_nodes         = 1
#   multi_az                = false
#   cluster_security_groups = [module.redshift_security_group.security_group_id]
#   iam_role_redshift_arn   = [module.redshift_role.redshift_s3_role_arn]
#   subnet_ids              = [module.private_subnet.subnet_ids["private-1-b"], module.private_subnet.subnet_ids["private-2-b"]]
#   # , module.private_subnet.subnet_ids["private-3-b"]]
#   depends_on = [module.redshift_role, module.redshift_security_group]
#   tags = merge(local.common_tags, {
#     Name = "${local.name}-redshift-cluster"
#     Type = "RedshiftCluster"
#   })
# }

# module "redis_security_group" {
#   source      = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/security_group?ref=v1.2.5"
#   name        = "${local.name}-redis-sg"
#   description = "Security group for redis"
#   vpc_id      = module.vpc.vpc_id
#   ingress_rules = [
#     {
#       from_port                = 6379
#       to_port                  = 6379
#       protocol                 = "tcp"
#       source_security_group_id = module.instance_security_group.security_group_id
#       description              = "Allow redis access from VPC"
#     }
#   ]
#   egress_rules = [
#     {
#       from_port   = 0
#       to_port     = 0
#       protocol    = "-1"
#       cidr_blocks = ["0.0.0.0/0"]
#       description = "Allow all outbound traffic"
#     }
#   ]

#   tags = merge(local.common_tags, {
#     Name = "${local.name}-redis-sg"
#     Type = "SecurityGroup"
#   })
# }

# module "redis" {
#   source               = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/elasticache/replication_group/cluster_diasable?ref=v1.3.0"
#   cluster_id           = "${local.name}-elasticache"
#   cache_node_type      = "cache.t3.micro"
#   engine               = "redis"
#   engine_version       = "7.0"
#   parameter_group_name = "default.redis7"
#   multi_az_enabled     = false
#   num_cache_clusters   = 1
#   failover             = false
#   subnet_ids           = [module.private_subnet.subnet_ids["private-1-a"], module.private_subnet.subnet_ids["private-2-a"]]
#   security_group_ids   = [module.redis_security_group.security_group_id]
#   tags = merge(local.common_tags, {
#     Name = "${local.name}-elasticache"
#     Type = "Elasticache"
#   })
# }

# module "ssm_param" {
#   source = "git::https://github.com/protechanalysis/terraform-aws-module.git//aws_modules/ssm_parameters/general_param?ref=v1.3.1"
#   parameters = {
#     redis_host = {
#       description = "redis primary endpoint"
#       value       = module.redis.redis_primary_endpoint
#       type        = "String"
#     },
#     alb_dns = {
#       description = "alb dns name"
#       value       = module.load_balancer.alb_url
#       type        = "String"
#     },
#     db_host = {
#       description = "rds endpoint"
#       value       = split(":", module.rds.rds_endpoint)[0]
#       type        = "String"
#     },
#     db_name = {
#       description = "rds database name"
#       value       = module.rds.database_name
#       type        = "String"
#     },
#     db_username = {
#       description = "rds username"
#       value       = module.random_username.result
#       type        = "String"
#     },
#     db_password = {
#       description = "rds password"
#       value       = module.random_password.result
#       type        = "SecureString"
#     },
#     dwh_endpoint = {
#       description = " datawarehouse endpoint"
#       value       = split(":", module.redshift.redshift_cluster_endpoint)[0]
#       type        = "String"
#     }
#   }
# }
