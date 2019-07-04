resource "aws_vpc" "CDS-tools-vpc" {
  # Le référencement de la variable base_cidr_block permet de modifier
  # l'adressage réseau sans modifier la configuration.
  cidr_block           = var.base_cidr_block
  enable_dns_hostnames = true
  tags = {
    Name   = "CDS-tools-vpc"
    projet = "CDS-tools"
  }
}

resource "aws_subnet" "primaire" {
  # En référençant l'objet aws_vpc.main, Terraform sait que le
  # sous-réseau doit être créé uniquement après la création du VPC.
  vpc_id            = aws_vpc.CDS-tools-vpc.id
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  cidr_block        = "10.1.1.0/24"
  tags = {
    Name   = "CDS-tools-sn1"
    projet = "CDS-tools"
  }
}

resource "aws_subnet" "secondaire" {
  # En référençant l'objet aws_vpc.main, Terraform sait que le
  # sous-réseau doit être créé uniquement après la création du VPC.
  vpc_id            = aws_vpc.CDS-tools-vpc.id
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  cidr_block        = "10.1.2.0/24"
  tags = {
    Name   = "CDS-tools-sn2"
    projet = "CDS-tools"
  }
}

resource "aws_eip" "CDS-tools-EIP" {
  instance = "${aws_instance.CDS-tools-frontend.id}"
  vpc      = true
}


resource "aws_internet_gateway" "CDS-tools-gateway" {
  vpc_id = "${aws_vpc.CDS-tools-vpc.id}"

  tags = {
    Name = "CDS-tools"
  }
}

resource "aws_route_table" "CDS-tools-route-table" {
  vpc_id = "${aws_vpc.CDS-tools-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.CDS-tools-gateway.id}"
  }

  tags = {
    Name = "CDs-tools"
  }
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.primaire.id}"
  route_table_id = "${aws_route_table.CDS-tools-route-table.id}"
}
