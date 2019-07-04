resource "aws_efs_file_system" "efs-cluster-main" {
  creation_token = "efs-cluster-main"
  performance_mode	=	"generalPurpose"

  tags = {
    Name = "CDS-tools-efs"
  }
}

resource "aws_efs_mount_target" "efs-mt-ecs" {
  file_system_id  = "${aws_efs_file_system.efs-cluster-main.id}"
  subnet_id = "${aws_subnet.primaire.id}"
  security_groups = ["${aws_security_group.allow_efs.id}"]
}

