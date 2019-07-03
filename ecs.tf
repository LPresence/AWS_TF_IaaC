resource "aws_launch_configuration" "ecs-launch-config-gitlab" {
  name                        = "ecs-launch-configuration"
  image_id                    = "ami-071f4e4006f9c3211"
  instance_type               = "t2.small"
  #iam_instance_profile        = "${aws_iam_instance_profile.ecs-instance-profile.id}"

  root_block_device {
    volume_type = "standard"
    volume_size = 40
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }

  security_groups             = ["${aws_security_group.allow_to_cluster.id}"]
  associate_public_ip_address = "false"
  key_name                    = "diwocs"
  user_data                   = <<EOF
                                  #!/bin/bash
                                  echo ECS_CLUSTER=fr-nantes-im >> /etc/ecs/ecs.config
                                  EOF
}

resource "aws_autoscaling_group" "ecs-autoscaling-group-main-cluster" {
  name                        = "ecs-autoscaling-group"
  max_size                    = "1"
  min_size                    = "1"
  desired_capacity            = "1"
  vpc_zone_identifier         = ["${aws_subnet.primaire.id}"]#, "${aws_subnet.secondaire.id}"]
  launch_configuration        = "${aws_launch_configuration.ecs-launch-config-gitlab.name}"
  #health_check_type           = "ELB"
}

resource "aws_ecs_cluster" "cluster-main" {
  name = "fr-nantes-im"
  tags = {
    projet = "CDS-tools"
  }
}
