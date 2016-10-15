
resource "aws_subnet" "main" {
  cidr_block = "${cidrsubnet(data.aws_vpc.target.cidr_block, 4, var.subnet_offset)}"
  vpc_id     = "${var.vpc_id}"
  map_public_ip_on_launch = "${var.map_public_ip_on_launch}"
  tags {
    Name = "${var.subnet_name}"
  }
}

//resource "aws_route_table" "main" {
//  vpc_id = "${var.vpc_id}"
//}
//
//resource "aws_route_table_association" "main" {
//  subnet_id      = "${aws_subnet.main.id}"
//  route_table_id = "${aws_route_table.main.id}"
//}
