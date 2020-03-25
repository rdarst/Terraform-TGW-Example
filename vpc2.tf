resource "aws_vpc" "vpc2" {
  cidr_block = "172.22.0.0/16"
  tags = {
    Name = "TGW_VPC2"
  }
}

# Setup routes to VPC spokes on main route table
resource "aws_route" "vpc2_edge_tgw_access" {
  route_table_id         = aws_vpc.vpc_edge.main_route_table_id
  destination_cidr_block = "172.20.0.0/14"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

# Attach to vpc2
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attach_vpc2" {
  subnet_ids         = [aws_subnet.vpc2_webserver_subnet1.id, aws_subnet.vpc2_webserver_subnet2.id ]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.vpc2.id
}

# Grant the VPC internet access on its main route table via the TGW
resource "aws_route" "vpc2_internet_access" {
  route_table_id         = aws_vpc.vpc2.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

# Our default security group to access the instances over all ports
resource "aws_security_group" "vpc2_permissive" {
  name        = "vpc2_terraform_permissive_sg"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.vpc2.id

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
resource "aws_subnet" "vpc2_webserver_subnet1" {
  vpc_id                  = aws_vpc.vpc2.id
  cidr_block              = "172.22.5.0/24"
  map_public_ip_on_launch = false
  availability_zone       = var.primary_az
  tags = {
    Name = "VPC2-Webservers1"
  }
}

# Define a webserver subnet secondary availability zone
resource "aws_subnet" "vpc2_webserver_subnet2" {
  vpc_id                  = aws_vpc.vpc2.id
  cidr_block              = "172.22.6.0/24"
  map_public_ip_on_launch = false
  availability_zone       = var.secondary_az
  tags = {
    Name = "VPC2-Webservers2"
  }
}

# Create Ubuntu Instance in WebServer subnet 1
resource "aws_instance" "vpc2_web1" {
  ami           = data.aws_ami.ubuntu_ami.id
  instance_type = "t2.nano"
  private_ip = "172.22.5.20"
  subnet_id = aws_subnet.vpc2_webserver_subnet1.id
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.vpc2_permissive.id]
  associate_public_ip_address = false
  user_data     = file("userdata-web.sh")
  tags = {
 	Name = "VPC2_Web_Server1"
       }
}