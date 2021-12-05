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

### Sample Output
```
Terraform will perform the following actions:

  # aws_eip.eip will be created
  + resource "aws_eip" "eip" {
      + allocation_id        = (known after apply)
      + association_id       = (known after apply)
      + carrier_ip           = (known after apply)
      + customer_owned_ip    = (known after apply)
      + domain               = (known after apply)
      + id                   = (known after apply)
      + instance             = (known after apply)
      + network_border_group = (known after apply)
      + network_interface    = (known after apply)
      + private_dns          = (known after apply)
      + private_ip           = (known after apply)
      + public_dns           = (known after apply)
      + public_ip            = (known after apply)
      + public_ipv4_pool     = (known after apply)
      + tags                 = {
          + "Name"    = "techsupport-nat-eip"
          + "project" = "techsupport"
        }
      + tags_all             = {
          + "Name"    = "techsupport-nat-eip"
          + "project" = "techsupport"
        }
      + vpc                  = true
    }

  # aws_internet_gateway.igw will be created
  + resource "aws_internet_gateway" "igw" {
      + arn      = (known after apply)
      + id       = (known after apply)
      + owner_id = (known after apply)
      + tags     = {
          + "Name"    = "techsupport-igw"
          + "project" = "techsupport"
        }
      + tags_all = {
          + "Name"    = "techsupport-igw"
          + "project" = "techsupport"
        }
      + vpc_id   = (known after apply)
    }

  # aws_nat_gateway.nat will be created
  + resource "aws_nat_gateway" "nat" {
      + allocation_id        = (known after apply)
      + connectivity_type    = "public"
      + id                   = (known after apply)
      + network_interface_id = (known after apply)
      + private_ip           = (known after apply)
      + public_ip            = (known after apply)
      + subnet_id            = (known after apply)
      + tags                 = {
          + "Name"    = "techsupport-nat"
          + "project" = "techsupport"
        }
      + tags_all             = {
          + "Name"    = "techsupport-nat"
          + "project" = "techsupport"
        }
    }

  # aws_route_table.private will be created
  + resource "aws_route_table" "private" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + route            = [
          + {
              + carrier_gateway_id         = ""
              + cidr_block                 = "0.0.0.0/0"
              + destination_prefix_list_id = ""
              + egress_only_gateway_id     = ""
              + gateway_id                 = ""
              + instance_id                = ""
              + ipv6_cidr_block            = ""
              + local_gateway_id           = ""
              + nat_gateway_id             = (known after apply)
              + network_interface_id       = ""
              + transit_gateway_id         = ""
              + vpc_endpoint_id            = ""
              + vpc_peering_connection_id  = ""
            },
        ]
      + tags             = {
          + "Name"    = "techsupport-route-private"
          + "project" = "techsupport"
        }
      + tags_all         = {
          + "Name"    = "techsupport-route-private"
          + "project" = "techsupport"
        }
      + vpc_id           = (known after apply)
    }

  # aws_route_table.public will be created
  + resource "aws_route_table" "public" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + route            = [
          + {
              + carrier_gateway_id         = ""
              + cidr_block                 = "0.0.0.0/0"
              + destination_prefix_list_id = ""
              + egress_only_gateway_id     = ""
              + gateway_id                 = (known after apply)
              + instance_id                = ""
              + ipv6_cidr_block            = ""
              + local_gateway_id           = ""
              + nat_gateway_id             = ""
              + network_interface_id       = ""
              + transit_gateway_id         = ""
              + vpc_endpoint_id            = ""
              + vpc_peering_connection_id  = ""
            },
        ]
      + tags             = {
          + "Name"    = "techsupport-route-public"
          + "project" = "techsupport"
        }
      + tags_all         = {
          + "Name"    = "techsupport-route-public"
          + "project" = "techsupport"
        }
      + vpc_id           = (known after apply)
    }

  # aws_route_table_association.private1 will be created
  + resource "aws_route_table_association" "private1" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_route_table_association.private2 will be created
  + resource "aws_route_table_association" "private2" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_route_table_association.private3 will be created
  + resource "aws_route_table_association" "private3" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_route_table_association.public1 will be created
  + resource "aws_route_table_association" "public1" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_route_table_association.public2 will be created
  + resource "aws_route_table_association" "public2" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_route_table_association.public3 will be created
  + resource "aws_route_table_association" "public3" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_subnet.private1 will be created
  + resource "aws_subnet" "private1" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "ap-south-1a"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "172.16.96.0/19"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = false
      + owner_id                        = (known after apply)
      + tags                            = {
          + "Name"    = "techsupport-private1"
          + "project" = "techsupport"
        }
      + tags_all                        = {
          + "Name"    = "techsupport-private1"
          + "project" = "techsupport"
        }
      + vpc_id                          = (known after apply)
    }

  # aws_subnet.private2 will be created
  + resource "aws_subnet" "private2" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "ap-south-1b"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "172.16.128.0/19"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = false
      + owner_id                        = (known after apply)
      + tags                            = {
          + "Name"    = "techsupport-private2"
          + "project" = "techsupport"
        }
      + tags_all                        = {
          + "Name"    = "techsupport-private2"
          + "project" = "techsupport"
        }
      + vpc_id                          = (known after apply)
    }

  # aws_subnet.private3 will be created
  + resource "aws_subnet" "private3" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "ap-south-1c"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "172.16.160.0/19"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = false
      + owner_id                        = (known after apply)
      + tags                            = {
          + "Name"    = "techsupport-private3"
          + "project" = "techsupport"
        }
      + tags_all                        = {
          + "Name"    = "techsupport-private3"
          + "project" = "techsupport"
        }
      + vpc_id                          = (known after apply)
    }

  # aws_subnet.public1 will be created
  + resource "aws_subnet" "public1" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "ap-south-1a"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "172.16.0.0/19"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = true
      + owner_id                        = (known after apply)
      + tags                            = {
          + "Name"    = "techsupport-public1"
          + "project" = "techsupport"
        }
      + tags_all                        = {
          + "Name"    = "techsupport-public1"
          + "project" = "techsupport"
        }
      + vpc_id                          = (known after apply)
    }

  # aws_subnet.public2 will be created
  + resource "aws_subnet" "public2" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "ap-south-1b"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "172.16.32.0/19"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = true
      + owner_id                        = (known after apply)
      + tags                            = {
          + "Name"    = "techsupport-public2"
          + "project" = "techsupport"
        }
      + tags_all                        = {
          + "Name"    = "techsupport-public2"
          + "project" = "techsupport"
        }
      + vpc_id                          = (known after apply)
    }

  # aws_subnet.public3 will be created
  + resource "aws_subnet" "public3" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "ap-south-1c"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "172.16.64.0/19"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = true
      + owner_id                        = (known after apply)
      + tags                            = {
          + "Name"    = "techsupport-public3"
          + "project" = "techsupport"
        }
      + tags_all                        = {
          + "Name"    = "techsupport-public3"
          + "project" = "techsupport"
        }
      + vpc_id                          = (known after apply)
    }

  # aws_vpc.vpc will be created
  + resource "aws_vpc" "vpc" {
      + arn                            = (known after apply)
      + cidr_block                     = "172.16.0.0/16"
      + default_network_acl_id         = (known after apply)
      + default_route_table_id         = (known after apply)
      + default_security_group_id      = (known after apply)
      + dhcp_options_id                = (known after apply)
      + enable_classiclink             = (known after apply)
      + enable_classiclink_dns_support = (known after apply)
      + enable_dns_hostnames           = true
      + enable_dns_support             = true
      + id                             = (known after apply)
      + instance_tenancy               = "default"
      + ipv6_association_id            = (known after apply)
      + ipv6_cidr_block                = (known after apply)
      + main_route_table_id            = (known after apply)
      + owner_id                       = (known after apply)
      + tags                           = {
          + "Name"    = "techsupport-vpc"
          + "project" = "techsupport"
        }
      + tags_all                       = {
          + "Name"    = "techsupport-vpc"
          + "project" = "techsupport"
        }
    }

Plan: 18 to add, 0 to change, 0 to destroy.
```
Then need to apply the below command

```sh
 terraform apply
```
### Sample Output
```
Terraform will perform the following actions:

  # aws_eip.eip will be created
  + resource "aws_eip" "eip" {
      + allocation_id        = (known after apply)
      + association_id       = (known after apply)
      + carrier_ip           = (known after apply)
      + customer_owned_ip    = (known after apply)
      + domain               = (known after apply)
      + id                   = (known after apply)
      + instance             = (known after apply)
      + network_border_group = (known after apply)
      + network_interface    = (known after apply)
      + private_dns          = (known after apply)
      + private_ip           = (known after apply)
      + public_dns           = (known after apply)
      + public_ip            = (known after apply)
      + public_ipv4_pool     = (known after apply)
      + tags                 = {
          + "Name"    = "techsupport-nat-eip"
          + "project" = "techsupport"
        }
      + tags_all             = {
          + "Name"    = "techsupport-nat-eip"
          + "project" = "techsupport"
        }
      + vpc                  = true
    }

  # aws_internet_gateway.igw will be created
  + resource "aws_internet_gateway" "igw" {
      + arn      = (known after apply)
      + id       = (known after apply)
      + owner_id = (known after apply)
      + tags     = {
          + "Name"    = "techsupport-igw"
          + "project" = "techsupport"
        }
      + tags_all = {
          + "Name"    = "techsupport-igw"
          + "project" = "techsupport"
        }
      + vpc_id   = (known after apply)
    }

  # aws_nat_gateway.nat will be created
  + resource "aws_nat_gateway" "nat" {
      + allocation_id        = (known after apply)
      + connectivity_type    = "public"
      + id                   = (known after apply)
      + network_interface_id = (known after apply)
      + private_ip           = (known after apply)
      + public_ip            = (known after apply)
      + subnet_id            = (known after apply)
      + tags                 = {
          + "Name"    = "techsupport-nat"
          + "project" = "techsupport"
        }
      + tags_all             = {
          + "Name"    = "techsupport-nat"
          + "project" = "techsupport"
        }
    }

  # aws_route_table.private will be created
  + resource "aws_route_table" "private" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + route            = [
          + {
              + carrier_gateway_id         = ""
              + cidr_block                 = "0.0.0.0/0"
              + destination_prefix_list_id = ""
              + egress_only_gateway_id     = ""
              + gateway_id                 = ""
              + instance_id                = ""
              + ipv6_cidr_block            = ""
              + local_gateway_id           = ""
              + nat_gateway_id             = (known after apply)
              + network_interface_id       = ""
              + transit_gateway_id         = ""
              + vpc_endpoint_id            = ""
              + vpc_peering_connection_id  = ""
            },
        ]
      + tags             = {
          + "Name"    = "techsupport-route-private"
          + "project" = "techsupport"
        }
      + tags_all         = {
          + "Name"    = "techsupport-route-private"
          + "project" = "techsupport"
        }
      + vpc_id           = (known after apply)
    }

  # aws_route_table.public will be created
  + resource "aws_route_table" "public" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + route            = [
          + {
              + carrier_gateway_id         = ""
              + cidr_block                 = "0.0.0.0/0"
              + destination_prefix_list_id = ""
              + egress_only_gateway_id     = ""
              + gateway_id                 = (known after apply)
              + instance_id                = ""
              + ipv6_cidr_block            = ""
              + local_gateway_id           = ""
              + nat_gateway_id             = ""
              + network_interface_id       = ""
              + transit_gateway_id         = ""
              + vpc_endpoint_id            = ""
              + vpc_peering_connection_id  = ""
            },
        ]
      + tags             = {
          + "Name"    = "techsupport-route-public"
          + "project" = "techsupport"
        }
      + tags_all         = {
          + "Name"    = "techsupport-route-public"
          + "project" = "techsupport"
        }
      + vpc_id           = (known after apply)
    }

  # aws_route_table_association.private1 will be created
  + resource "aws_route_table_association" "private1" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_route_table_association.private2 will be created
  + resource "aws_route_table_association" "private2" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_route_table_association.private3 will be created
  + resource "aws_route_table_association" "private3" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_route_table_association.public1 will be created
  + resource "aws_route_table_association" "public1" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_route_table_association.public2 will be created
  + resource "aws_route_table_association" "public2" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_route_table_association.public3 will be created
  + resource "aws_route_table_association" "public3" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_subnet.private1 will be created
  + resource "aws_subnet" "private1" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "ap-south-1a"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "172.16.96.0/19"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = false
      + owner_id                        = (known after apply)
      + tags                            = {
          + "Name"    = "techsupport-private1"
          + "project" = "techsupport"
        }
      + tags_all                        = {
          + "Name"    = "techsupport-private1"
          + "project" = "techsupport"
        }
      + vpc_id                          = (known after apply)
    }

  # aws_subnet.private2 will be created
  + resource "aws_subnet" "private2" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "ap-south-1b"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "172.16.128.0/19"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = false
      + owner_id                        = (known after apply)
      + tags                            = {
          + "Name"    = "techsupport-private2"
          + "project" = "techsupport"
        }
      + tags_all                        = {
          + "Name"    = "techsupport-private2"
          + "project" = "techsupport"
        }
      + vpc_id                          = (known after apply)
    }

  # aws_subnet.private3 will be created
  + resource "aws_subnet" "private3" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "ap-south-1c"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "172.16.160.0/19"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = false
      + owner_id                        = (known after apply)
      + tags                            = {
          + "Name"    = "techsupport-private3"
          + "project" = "techsupport"
        }
      + tags_all                        = {
          + "Name"    = "techsupport-private3"
          + "project" = "techsupport"
        }
      + vpc_id                          = (known after apply)
    }

  # aws_subnet.public1 will be created
  + resource "aws_subnet" "public1" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "ap-south-1a"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "172.16.0.0/19"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = true
      + owner_id                        = (known after apply)
      + tags                            = {
          + "Name"    = "techsupport-public1"
          + "project" = "techsupport"
        }
      + tags_all                        = {
          + "Name"    = "techsupport-public1"
          + "project" = "techsupport"
        }
      + vpc_id                          = (known after apply)
    }

  # aws_subnet.public2 will be created
  + resource "aws_subnet" "public2" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "ap-south-1b"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "172.16.32.0/19"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = true
      + owner_id                        = (known after apply)
      + tags                            = {
          + "Name"    = "techsupport-public2"
          + "project" = "techsupport"
        }
      + tags_all                        = {
          + "Name"    = "techsupport-public2"
          + "project" = "techsupport"
        }
      + vpc_id                          = (known after apply)
    }

  # aws_subnet.public3 will be created
  + resource "aws_subnet" "public3" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "ap-south-1c"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "172.16.64.0/19"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = true
      + owner_id                        = (known after apply)
      + tags                            = {
          + "Name"    = "techsupport-public3"
          + "project" = "techsupport"
        }
      + tags_all                        = {
          + "Name"    = "techsupport-public3"
          + "project" = "techsupport"
        }
      + vpc_id                          = (known after apply)
    }

  # aws_vpc.vpc will be created
  + resource "aws_vpc" "vpc" {
      + arn                            = (known after apply)
      + cidr_block                     = "172.16.0.0/16"
      + default_network_acl_id         = (known after apply)
      + default_route_table_id         = (known after apply)
      + default_security_group_id      = (known after apply)
      + dhcp_options_id                = (known after apply)
      + enable_classiclink             = (known after apply)
      + enable_classiclink_dns_support = (known after apply)
      + enable_dns_hostnames           = true
      + enable_dns_support             = true
      + id                             = (known after apply)
      + instance_tenancy               = "default"
      + ipv6_association_id            = (known after apply)
      + ipv6_cidr_block                = (known after apply)
      + main_route_table_id            = (known after apply)
      + owner_id                       = (known after apply)
      + tags                           = {
          + "Name"    = "techsupport-vpc"
          + "project" = "techsupport"
        }
      + tags_all                       = {
          + "Name"    = "techsupport-vpc"
          + "project" = "techsupport"
        }
    }

Plan: 18 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_vpc.vpc: Creating...
aws_eip.eip: Creating...
aws_eip.eip: Creation complete after 1s [id=eipalloc-0a057703a3a5c4b0d]
aws_vpc.vpc: Still creating... [10s elapsed]
aws_vpc.vpc: Creation complete after 14s [id=vpc-0db464682aed24013]
aws_subnet.public2: Creating...
aws_subnet.public1: Creating...
aws_subnet.private2: Creating...
aws_subnet.public3: Creating...
aws_subnet.private1: Creating...
aws_internet_gateway.igw: Creating...
aws_subnet.private3: Creating...
aws_subnet.private3: Creation complete after 1s [id=subnet-0b47f1d5b58b0289d]
aws_subnet.private1: Creation complete after 1s [id=subnet-07560f9a3b0f61a7a]
aws_internet_gateway.igw: Creation complete after 1s [id=igw-0239424656479ccef]
aws_subnet.private2: Creation complete after 1s [id=subnet-017941c233206edd1]
aws_route_table.public: Creating...
aws_route_table.public: Creation complete after 2s [id=rtb-0e8a0817984124a63]
aws_subnet.public2: Still creating... [10s elapsed]
aws_subnet.public1: Still creating... [10s elapsed]
aws_subnet.public3: Still creating... [10s elapsed]
aws_subnet.public2: Creation complete after 12s [id=subnet-0d0c1e2fd4f5b5245]
aws_subnet.public1: Creation complete after 12s [id=subnet-05eaec743b2e3ae78]
aws_subnet.public3: Creation complete after 12s [id=subnet-01ec0021945ebc361]
aws_route_table_association.public1: Creating...
aws_route_table_association.public2: Creating...
aws_route_table_association.public3: Creating...
aws_nat_gateway.nat: Creating...
aws_route_table_association.public1: Creation complete after 1s [id=rtbassoc-0f98d087ad3ee13c5]
aws_route_table_association.public3: Creation complete after 1s [id=rtbassoc-041678f3203e4f480]
aws_route_table_association.public2: Creation complete after 1s [id=rtbassoc-00abdc76a567f78e0]
aws_nat_gateway.nat: Still creating... [10s elapsed]
aws_nat_gateway.nat: Still creating... [20s elapsed]
aws_nat_gateway.nat: Still creating... [30s elapsed]
aws_nat_gateway.nat: Still creating... [40s elapsed]
aws_nat_gateway.nat: Still creating... [50s elapsed]
aws_nat_gateway.nat: Still creating... [1m0s elapsed]
aws_nat_gateway.nat: Still creating... [1m10s elapsed]
aws_nat_gateway.nat: Still creating... [1m20s elapsed]
aws_nat_gateway.nat: Still creating... [1m30s elapsed]
aws_nat_gateway.nat: Still creating... [1m40s elapsed]
aws_nat_gateway.nat: Still creating... [1m50s elapsed]
aws_nat_gateway.nat: Creation complete after 1m58s [id=nat-04d2f552ffae2ebb7]
aws_route_table.private: Creating...
aws_route_table.private: Creation complete after 2s [id=rtb-097f3867269b1cd5f]
aws_route_table_association.private1: Creating...
aws_route_table_association.private2: Creating...
aws_route_table_association.private3: Creating...
aws_route_table_association.private1: Creation complete after 0s [id=rtbassoc-0e42fe76b11fa9341]
aws_route_table_association.private2: Creation complete after 0s [id=rtbassoc-05f09299e1733e463]
aws_route_table_association.private3: Creation complete after 0s [id=rtbassoc-013ab12543db6e5b6]

Apply complete! Resources: 18 added, 0 changed, 0 destroyed.
```

## Result

From the above I have built an architecture for VPC named "techsupport" using terraform as IaC[Infrastructure as Code] and it makes the whole process automates. Also we can easily customize as the customization is required only in a single file.
