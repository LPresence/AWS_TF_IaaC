resource "aws_instance" "CDS-tools-frontend" {
  ami           = "ami-07d80b16fe4b2de61"
  instance_type = "t2.small"
  security_groups	= ["${aws_security_group.allow_front.id}"]
  subnet_id	=	aws_subnet.primaire.id
  key_name	=	"diwocs"
  provisioner "file" {
    source	=	"test.sh"
    destination	=	"/test.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /test.sh",
      "/bin/bash /test.sh",
    ]
  }
  tags = {
    Name	=	"CDS-zinternet"
    projet = "CDS-tools"
  }
}