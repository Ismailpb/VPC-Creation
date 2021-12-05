variable "region" {

  description = "Amazon Default Region"    
  default = "ap-south-1"
}

variable "project" {
  default = "techsupport"
}

variable "vpc_cidr" { 
  default = "172.16.0.0/16"
}
