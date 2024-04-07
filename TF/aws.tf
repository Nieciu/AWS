resource "aws_vpc" "project" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.project.id
    cidr_block = "10.0.0.0/24"
    availability_zone = var.region
}