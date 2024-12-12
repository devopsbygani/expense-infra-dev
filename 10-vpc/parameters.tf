resource "aws_ssm_parameter" "vpc_id" {
  name  = "/${var.project_name}/${var.environment}/vpc_id"
  type  = "String"
  value = module.aws_vpc.vpc_info
}

resource "aws_ssm_parameter" "public_subnet_ids" {
  name  = "/${var.project_name}/${var.environment}/public_subnet_ids"
  type  = "StringList"
  value = join(",",module.aws_vpc.public_subnet_ids)
}

resource "aws_ssm_parameter" "private_subnet_ids" {
  name  = "/${var.project_name}/${var.environment}/private_subnet_ids"
  type  = "StringList"
  value = join(",",module.aws_vpc.private_subnet_ids)
}

resource "aws_ssm_parameter" "database_subnet_ids" {
  name  = "/${var.project_name}/${var.environment}/database_subnet_ids"
  type  = "StringList"
  value = join(",",module.aws_vpc.database_subnet_ids)
}

resource "aws_ssm_parameter" "database_subnet_group_name" {
  name  = "/${var.project_name}/${var.environment}/database_subnet_group_name"
  type  = "String"
  value = module.aws_vpc.database_subnet_group_name
}


# my_list = ["foo", "bar", "xid", "b59"] before 
# my_var = join(", ", my_list)
# my_var = "foo, bar, xid, b59"  after