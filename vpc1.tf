resource "aws_vpc" "vpc1" {
  cidr_block = "172.21.0.0/16"
  tags = {
    Name = "TGW_VPC1"
  }
}

# Setup routes to VPC spokes on main route table
resource "aws_route" "vpc1_edge_tgw_access" {
  route_table_id         = aws_vpc.vpc_edge.main_route_table_id
  destination_cidr_block = "172.20.0.0/14"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

# Attach  TGW to vpc1
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attach_vpc1" {
  subnet_ids         = [aws_subnet.vpc1_webserver_subnet1.id, aws_subnet.vpc1_webserver_subnet2.id ]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.vpc1.id
}

# Grant the VPC internet access on its main route table
resource "aws_route" "vpc1_internet_access" {
  route_table_id         = aws_vpc.vpc1.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

# Our default security group to access the instances over all ports
resource "aws_security_group" "vpc1_permissive" {
  name        = "vpc1_terraform_permissive_sg"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.vpc1.id

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

# Define a webserver subnet primary availability zone
resource "aws_subnet" "vpc1_webserver_subnet1" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "172.21.5.0/24"
  map_public_ip_on_launch = false
  availability_zone       = var.primary_az
  tags = {
    Name = "VPC1-Webservers1"
  }
}

# Define a webserver subnet secondary availability zone
resource "aws_subnet" "vpc1_webserver_subnet2" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "172.21.6.0/24"
  map_public_ip_on_launch = false
  availability_zone       = var.secondary_az
  tags = {
    Name = "VPC1-Webservers2"
  }
}

# Create Ubuntu Instance in WebServer subnet 1
resource "aws_instance" "vpc1_web1" {
  ami           = data.aws_ami.ubuntu_ami.id
  instance_type = "t2.nano"
  private_ip = "172.21.5.20"
  subnet_id = aws_subnet.vpc1_webserver_subnet1.id
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.vpc1_permissive.id]
  associate_public_ip_address = false
  user_data     = file("userdata-web.sh")
  tags = {
 	Name = "VPC1_Web_Server1"
       }
}