variable "project_name" {
    default = "expense"
}

variable "environment" {
    default = "dev"
}

variable "common_tags" {
    default = {
        Project = "expense"
        Terraform = "true"
        Environment = "dev"
    }
}

variable "acm_tags" {
    default = {
        component = "acm"
    }
}

variable "zone_name" {
    default = "devgani.online"
}

variable "zone_id" {
    default = "Z08507192LTGIE6IND07Q"
}