module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = local.resource_name  #expense-dev

  engine            = "mysql"  # postgress,mysql,oracle
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 5

  db_name  = "transactions"
  username = "root"
  manage_master_user_password = false
  password = "ExpenseApp1"
  port     = "3306"

  #iam_database_authentication_enabled = true # default false

  vpc_security_group_ids = [local.mysql_sg_id]  # provide database security group id
  skip_final_snapshot = true   # default is false, become difficult while deleting vpc.

  # Enhanced Monitoring - see example for details on how to create the role
  # by yourself, in case you don't want to create it automatically
#   monitoring_interval    = "30"
#   monitoring_role_name   = "MyRDSMonitoringRole"
#   create_monitoring_role = true

  tags = merge(var.common_tags,var.rds_tags,
  {
    Owner       = "user"
    Environment = "dev"
  })

  # DB subnet group
#   create_db_subnet_group = true
#   subnet_ids             = ["subnet-12345678", "subnet-87654321"]
  db_subnet_group_name = local.database_subnet_group_name
  # DB parameter group
  family = "mysql8.0"

  # DB option group
  major_engine_version = "8.0"

  # Database Deletion Protection
#   deletion_protection = true

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"

  zone_name = var.zone_name

  records = [
    {
      name    = "mysql-${var.environment}"  #mysql-dev.devgani.online
      type    = "CNAME"
      ttl     = 1
      records = [
        module.db.db_instance_address
      ]
      allow_overwrite = true
    },
  ]
}

