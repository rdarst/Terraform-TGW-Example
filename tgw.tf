#Create TGW
resource "aws_ec2_transit_gateway" "tgw" {
  description = "tgw"
  tags = {
    Name = "TGW"
  }
}
# Attach to vpc1
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attach_vpc1" {
  subnet_ids         = [aws_subnet.vpc1_webserver_subnet1.id, aws_subnet.vpc1_webserver_subnet2.id ]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.vpc1.id
}

# Attach to vpc2
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attach_vpc2" {
  subnet_ids         = [aws_subnet.vpc2_webserver_subnet1.id, aws_subnet.vpc2_webserver_subnet2.id ]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.vpc2.id
}

# Attach to vpc_edge
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attach_edge" {
  subnet_ids         = [aws_subnet.vpc_edge_nat_internal.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.vpc_edge.id
}

# Set the default route to send traffic to the edge VPC
resource "aws_ec2_transit_gateway_route" "adddefault" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_attach_edge.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tgw.association_default_route_table_id
}