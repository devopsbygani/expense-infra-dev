module "aws_vpc" {
    source = "../../terraform_aws_vpc"
    project = var.project_name
    envirnoment = var.environment
    public_subnet_cidrs = var.public_subnet_cidrs
    private_subnet_cidrs =  var.private_subnet_cidrs
    database_subnet_cidrs = var.database_subnet_cidrs
    is_peering_requried = true 
 
}