# VPC Creation using Terraform

In this project we are going to create a VPS in an automated way and the VPC creation contains 3 public subnets and 3 private subnets which is configured via NAT gateway. The availability zones are automatically fetched via data source and which makes the VPC creation more simple.

## Resources Used

- 3 Public Subnet
- 3 Private Subnet
- Internet Gateway
- NAT Gateway
- 2 Route Tables (Private and Public)
- 1 Elastic IP

## Features

- Fully Automated creation of VPC 
- It can be deployed in any region and will be fetching the available zones in that region automatically using data source AZ. 
- Public and private subnets will be deployed in each AZ in an automated way.
- Every subnet CIDR block has been calculated automatically using cidrsubnet function
- Whole project can be managed from a single file (terraform.tfvars) which means selecting the region, changing the whole project name, selecting VPC, and subnetting.

## Prerequisites​

- Knowledge in AWS services, especially VPC, subnetting
- IAM user with necessary privileges. 


