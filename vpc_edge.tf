resource "aws_vpc" "vpc_edge" {
  cidr_block = "172.20.0.0/16"
  tags = {
    Name = "TGW_VPC_Edge"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "vpc_edge_igw" {
  vpc_id = aws_vpc.vpc_edge.id
}

# Grant the VPC internet access on its main route table
resource "aws_route" "vpc_edge_internet_access" {
  route_table_id         = aws_vpc.vpc_edge.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc_edge_igw.id
}

# Setup routes to VPC1 on main route table
resource "aws_route" "vpc1_edge_tgw_access" {
  route_table_id         = aws_vpc.vpc_edge.main_route_table_id
  destination_cidr_block = "172.21.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

# Setup routes to VPC2 on main route table
resource "aws_route" "vpc2_edge_tgw_access" {
  route_table_id         = aws_vpc.vpc_edge.main_route_table_id
  destination_cidr_block = "172.22.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

# Create Internal Route Table
resource "aws_route_table" "internalrt" {
  vpc_id = aws_vpc.vpc_edge.id
  route {
    cidr_block = "0.0.0.0/0"
    network_interface_id = aws_network_interface.nat_nic2.id
    instance_id = aws_instance.vpc_edge_web1.id
   }
  route {
    cidr_block = "172.21.0.0/16"
    transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
   }
  route {
    cidr_block = "172.22.0.0/16"
    transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
   }
  }

resource "aws_route_table_association" "natInternalassociation" {
    subnet_id      = aws_subnet.vpc_edge_nat_internal.id
    route_table_id = aws_route_table.internalrt.id
  }

# Our default security group to access the instances over all ports
resource "aws_security_group" "vpc_edge_permissive" {
  name        = "vpc_edge_terraform_permissive_sg"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.vpc_edge.id

  # access from the internet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define a NAT subnet primary availability zone
resource "aws_subnet" "vpc_edge_nat_external" {
  vpc_id                  = aws_vpc.vpc_edge.id
  cidr_block              = "172.20.0.0/24"
  map_public_ip_on_launch = false
  availability_zone       = var.primary_az
  tags = {
    Name = "vpc_edge-nat-external"
  }
}

# Define a NAT subnet primary availability zone
resource "aws_subnet" "vpc_edge_nat_internal" {
  vpc_id                  = aws_vpc.vpc_edge.id
  cidr_block              = "172.20.1.0/24"
  map_public_ip_on_launch = false
  availability_zone       = var.primary_az
  tags = {
    Name = "vpc_edge-nat-internal"
  }
}

# Create Nics needed for NAT Instance
resource "aws_network_interface" "nat_nic1" {
  subnet_id   = aws_subnet.vpc_edge_nat_external.id
  private_ips = ["172.20.0.10"]
  security_groups = [aws_security_group.vpc_edge_permissive.id]
  source_dest_check = false
  tags = {
    Name = "external_network_interface"
  }
}

resource "aws_network_interface" "nat_nic2" {
  subnet_id   = aws_subnet.vpc_edge_nat_internal.id
  private_ips = ["172.20.1.10"]
  security_groups = [aws_security_group.vpc_edge_permissive.id]
  source_dest_check = false
  tags = {
    Name = "internal_network_interface"
  }
}

# Create Ubuntu Instance 
resource "aws_instance" "vpc_edge_web1" {
  ami           = data.aws_ami.ubuntu_ami.id
  instance_type = "t2.nano"
  key_name      = var.key_name
  user_data     = file("userdata-natgateway.sh")
  tags = {
 	Name = "vpc_edge_NAT_Instance"
       }
  network_interface {
      network_interface_id = aws_network_interface.nat_nic1.id
      device_index = 0
      }
  network_interface {
      network_interface_id = aws_network_interface.nat_nic2.id
      device_index = 1
      }
}

#Create EIP for the Check Point Gateway Server only create if IGW has been created
resource "aws_eip" "NAT_EIP" {
  network_interface = aws_network_interface.nat_nic1.id
  vpc      = true
  depends_on = [aws_internet_gateway.vpc_edge_igw]
}

# Output the public ip of the gateway
output "NAT_public_ip" {
    value = aws_eip.NAT_EIP.public_ip
}