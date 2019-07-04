resource "aws_security_group" "allow_front" {
  name        = "front_access_sg"
  description = "Allow HTTP/S/SSH inbound traffic"
  vpc_id      = "${aws_vpc.CDS-tools-vpc.id}"

  ingress {
    # HTTPS
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # HTTP
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # SSH
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    projet = "CDS-tools"
  }
}

resource "aws_security_group" "allow_to_cluster" {
  name        = "cluster_access_sg"
  description = "Allow HTTP/S/SSH inbound traffic"
  vpc_id      = "${aws_vpc.CDS-tools-vpc.id}"

  ingress {
    #SSH
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    #HTTP
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    #HTTPS
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    projet = "CDS-tools"
  }
}

resource "aws_security_group" "allow_efs" {
  name   = "allow_efs_access_sg"
  vpc_id = "${aws_vpc.CDS-tools-vpc.id}"

  // NFS
  ingress {
    security_groups = ["${aws_security_group.allow_to_cluster.id}"]
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
  }

  // Terraform removes the default rule
  egress {
    security_groups = ["${aws_security_group.allow_to_cluster.id}"]
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
  }
}
