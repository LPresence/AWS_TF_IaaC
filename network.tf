resource "aws_vpc" "CDS-tools-vpc" {
  # Le référencement de la variable base_cidr_block permet de modifier
  # l'adressage réseau sans modifier la configuration.
  cidr_block           = var.base_cidr_block
  enable_dns_hostnames = true
  tags = {
    Name   = "CDS-main-vpc"
    projet = "CDS-tools"
  }
}

resource "aws_subnet" "primaire" {
  # En référençant l'objet aws_vpc.main, Terraform sait que le
  # sous-réseau doit être créé uniquement après la création du VPC.
  vpc_id            = aws_vpc.CDS-tools-vpc.id
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  cidr_block        = var.subnet_public
  tags = {
    Name   = "CDS-tools-pubsn"
    projet = "CDS-tools"
  }
}

resource "aws_subnet" "secondaire" {
  # En référençant l'objet aws_vpc.main, Terraform sait que le
  # sous-réseau doit être créé uniquement après la création du VPC.
  vpc_id            = aws_vpc.CDS-tools-vpc.id
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  cidr_block        = var.subnet_private
  tags = {
    Name   = "CDS-tools-privsn"
    projet = "CDS-tools"
  }
}

###
# Public subnet
###
resource "aws_eip" "CDS-tools-EIP" {
  instance = "${aws_instance.CDS-tools-frontend.id}"
  vpc      = true
}


resource "aws_internet_gateway" "CDS-tools-gateway" {
  vpc_id = "${aws_vpc.CDS-tools-vpc.id}"

  tags = {
    Name  = "CDS-igw"
    projet = "CDS-tools"
  }
}

resource "aws_route_table" "CDS-tools-route-table" {
  vpc_id = "${aws_vpc.CDS-tools-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.CDS-tools-gateway.id}"
  }

  tags = {
    Name = "CDS-pub-rt"
  }
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.primaire.id}"
  route_table_id = "${aws_route_table.CDS-tools-route-table.id}"
}


###
# Private subnet
###

resource "aws_eip" "CDS-nat-ip" {
  vpc      = true
}

resource "aws_nat_gateway" "CDS-nat-gw" {
  allocation_id = "${aws_eip.CDS-nat-ip.id}"
  subnet_id     = "${aws_subnet.secondaire.id}"

  tags = {
    Name = "CDS-ngw"
    projet = "CDS-tools"
  }
}

resource "aws_route_table" "CDS-priv-rt" {
  vpc_id = "${aws_vpc.CDS-tools-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.CDS-nat-gw.id}"
  }

  tags = {
    Name = "CDS-pub-rt"
  }
}

resource "aws_route_table_association" "priv-subnet-association" {
  subnet_id      = "${aws_subnet.secondaire.id}"
  route_table_id = "${aws_route_table.CDS-priv-rt.id}"
}

//resource "aws_network_interface" "test" {
//  subnet_id       = "${aws_subnet.secondaire.id}"
//  description = "Interface for NAT Gateway"
//  security_groups = ["${aws_security_group.allow_nat_internet.id}"]
//}