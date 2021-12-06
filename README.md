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
- Whole project can be managed from a single file (vpc.tf) which means selecting the region, changing the whole project name, selecting VPC, and subnetting.

## Prerequisites​

- Knowledge in AWS services, especially VPC, subnetting
- IAM user with necessary privileges. 

## Procedure

At first we need to create a variable file named "variable.tf" whch includes the following
-region
-projectname
-cidr block(Here I have taken the VPC CIDR as 172.16.0.0/16 and subnetcidr as 3 for my project, for the creation of a total of 6 subnets (3 - public and 3private)

```
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

```
For the above-mentioned variables, values are passed into the file vpc.tf

Next we need to create a provider.tf file and which includes the region,accesskey and secret key

```
provider "aws" {
  region     = "region name"
  access_key = "XXXXXXXXXXX"
  secret_key = "XXXXXXXXXXXXXXXXXXX"
}
```

Once the provider and variables files ready, we can move to create VPC in vpc.tf
### Fetching AZ Names
```
data "aws_availability_zones" "az" {
    
  state = "available"

}
```
### VPC Creation
```
resource "aws_vpc" "vpc" {
    
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true  
  tags = {
    Name = "${var.project}-vpc"
    project = var.project
  }
  lifecycle {
    create_before_destroy = true
  }
}
```

Once the VPC is created, we can now proceed with the craetion of Internet Gateway(IGW)

### Attaching Internet GateWay
 
```
resource "aws_internet_gateway" "igw" {
    
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.project}-igw"
    project = var.project
  }
    
}

```
In the next part, we need to subnets and here am going to create 3 public subnets and 3 private subnets

### Creating Subnets Public1

```
resource "aws_subnet" "public1" {
    
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = cidrsubnet(var.vpc_cidr,3,0)                        
  map_public_ip_on_launch  = true
  availability_zone        = data.aws_availability_zones.az.names[0]
  tags = {
    Name = "${var.project}-public1"
    project = var.project
  }
}
```
### Creating Subnets Public2
```
resource "aws_subnet" "public2" {
    
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = cidrsubnet(var.vpc_cidr,3,1)
  map_public_ip_on_launch  = true
  availability_zone        = data.aws_availability_zones.az.names[1]
  tags = {
    Name = "${var.project}-public2"
    project = var.project
  }
}
```
### Creating Subnets Public3
```
resource "aws_subnet" "public3" {
    
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = cidrsubnet(var.vpc_cidr,3,2)
  map_public_ip_on_launch  = true
  availability_zone        = data.aws_availability_zones.az.names[2]
  tags = {
    Name = "${var.project}-public3"
    project = var.project
  }
}
```
### Creating Subnets Private1
```
resource "aws_subnet" "private1" {
    
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = cidrsubnet(var.vpc_cidr,3,3)
  map_public_ip_on_launch  = false
  availability_zone        = data.aws_availability_zones.az.names[0]
  tags = {
    Name = "${var.project}-private1"
    project = var.project
  }
}
```
### Creating Subnets Private2
```
resource "aws_subnet" "private2" {
    
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = cidrsubnet(var.vpc_cidr,3,4)
  map_public_ip_on_launch  = false
  availability_zone        = data.aws_availability_zones.az.names[1]
  tags = {
    Name = "${var.project}-private2"
    project = var.project
  }
}
```
### Creating Subnets Private3
```
resource "aws_subnet" "private3" {
    
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = cidrsubnet(var.vpc_cidr,3,5)
  map_public_ip_on_launch  = false
  availability_zone        = data.aws_availability_zones.az.names[2]
  tags = {
    Name = "${var.project}-private3"
    project = var.project
  }
}
```
In order to configure private route table, we need to setup NAT Gateway and Elastic IP 
### Creating Nat GateWay
```
resource "aws_nat_gateway" "nat" {
    
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public2.id

  tags     = {
    Name    = "${var.project}-nat"
    project = var.project
  }

}
```
### Elastic IP Allocation
```
resource "aws_eip" "eip" {
  vpc      = true
  tags     = {
    Name    = "${var.project}-nat-eip"
    project = var.project
  }
}
```

Next we need to route the subnets for that we need to create the public and private route table and association

### RouteTable Creation public
```
resource "aws_route_table" "public" {
    
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags     = {
    Name    = "${var.project}-route-public"
    project = var.project
  }
}
```
### RouteTable Creation Private
```
resource "aws_route_table" "private" {
    
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags     = {
    Name    = "${var.project}-route-private"
    project = var.project
  }
}
```
### RouteTable Association Subnet Public1  rtb public
```
resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}
```
### RouteTable Association Subnet Public2  rtb public
```
resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}
```
### RouteTable Association Subnet Public3  rtb public
```
resource "aws_route_table_association" "public3" {
  subnet_id      = aws_subnet.public3.id
  route_table_id = aws_route_table.public.id
}
```
### RouteTable Association Subnet Private1  rtb public
```
resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}
```
### RouteTable Association Subnet private2  rtb public
```
resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}
```
### RouteTable Association Subnet private3  rtb public
```
resource "aws_route_table_association" "private3" {
  subnet_id      = aws_subnet.private3.id
  route_table_id = aws_route_table.private.id
}
```

Now the creation of VPC is completed.

### Terraform Installation 

- Clone the git repo and proceed with the installation of terraform if it has not been installed, otherwise ignore this step. Change the permission of the script - install.sh to executable and execute the bash script for the installation. 

- For Manual Proccedure 

- For Downloading -  [Terraform](https://www.terraform.io/downloads.html) 

- Installation Steps -  [Installation](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started)


After completing these,  initialize the working directory for Terraform configuration using the below command

```sh
terraform init
```
- Validate the terraform file using the command given below.

```sh
 terraform validate
```
- After successful validation, plan the build architecture and confirm the changes

```sh
 terraform plan
```
- Apply the changes to the AWS architecture

Then need to apply the below command

```sh
 terraform apply
```

## Result

From the above I have built an architecture for VPC named "techsupport" using terraform as IaC[Infrastructure as Code] and it makes the whole process automates. Also we can easily customize as the customization is required only in a single file.
