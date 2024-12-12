output "vpc_info" {
    value = module.aws_vpc.vpc_info
}

output "avaiable_zone" {
  value = module.aws_vpc.avaiable_zone
}

# default vpc info.
output "default_vpc_info" {
  value = module.aws_vpc.default_vpc_info
}

#deafult vpc route table info for peering 
output "routes_table_info" {
  value = module.aws_vpc.routes_table_info
}

output "public_subnet_ids" {
  value = module.aws_vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.aws_vpc.private_subnet_ids
}

output "database_subnet_ids" {
  value = module.aws_vpc.database_subnet_ids
}

