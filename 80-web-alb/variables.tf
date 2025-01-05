variable "common_tags" {
    default = {
    Environment = "Development"
    Project     = "expense"
  }
}

variable "web_alb_tags" {
    default = {
        component = "web-alb"
    }
}

variable "project_name" {
    default = "expense"
}

variable "environment" {
    default = "dev"
}

variable "zone_name" {
    default = "devgani.online"
}