####################################
######  DEFINITION VARIABLES  ######
####################################

variable "aws_region" {
	description = "Région AWS à utiliser"
	default = "eu-west-3"
}

variable "base_cidr_block" {
  description = "Adressage CIDR /16 , tel que 10.1.0.0/16, utilisé par le VPC"
  default = "10.1.0.0/16"
}

# Declare the data source
data "aws_availability_zones" "available" {
  state = "available"
}


###################################
######  DEFINITION PROVIDER  ######
###################################

provider "aws" {
  profile    = "default"
  region     = var.aws_region
}

##################################
######  DEFINITION NETWORK  ######
##################################

resource "aws_vpc" "CDS-tools-vpc" {
  # Le référencement de la variable base_cidr_block permet de modifier 
  # l'adressage réseau sans modifier la configuration.
  cidr_block = var.base_cidr_block
  enable_dns_hostnames = true
  tags = {
    Name	=	"CDS-tools-vpc"
	projet = "CDS-tools"
  }
}

resource "aws_subnet" "primaire" {
  # En référençant l'objet aws_vpc.main, Terraform sait que le
  # sous-réseau doit être créé uniquement après la création du VPC.
  vpc_id = aws_vpc.CDS-tools-vpc.id
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  cidr_block = "10.1.1.0/24"
  tags = {
	Name	=	"CDS-tools-sn1"
	projet = "CDS-tools"
  }
}

resource "aws_subnet" "secondaire" {
  # En référençant l'objet aws_vpc.main, Terraform sait que le
  # sous-réseau doit être créé uniquement après la création du VPC.
  vpc_id = aws_vpc.CDS-tools-vpc.id
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  cidr_block = "10.1.2.0/24"
  tags = {
	Name	=	"CDS-tools-sn2"
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

#########################################
######  DEFINITION SECURITY GROUP  ######
#########################################

resource "aws_security_group" "allow_front" {
  name        = "front_access_sg"
  description = "Allow HTTP/S/SSH inbound traffic"
  vpc_id	=	"${aws_vpc.CDS-tools-vpc.id}"

  ingress {
    # HTTPS 
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # HTTP 
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # SSH 
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
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
    name = "cluster_access_sg"
    description = "Allow HTTP/S/SSH inbound traffic"
    vpc_id		=	"${aws_vpc.CDS-tools-vpc.id}"

   #ingress {
	#	#SSH
    #   from_port = 22
   #    to_port = 22
   #    protocol = "tcp"
   #    cidr_blocks = ["0.0.0.0/0"]
  # }

   ingress {
		#HTTP
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
   }

   ingress {
		#HTTPS
      from_port = 443		
      to_port = 443
      protocol = "tcp"
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
   name = "allow_efs_access_sg"
   vpc_id = "${aws_vpc.CDS-tools-vpc.id}"

   // NFS
   ingress {
     security_groups = ["${aws_security_group.allow_to_cluster.id}"]
     from_port = 2049
     to_port = 2049
     protocol = "tcp"
   }

   // Terraform removes the default rule
   egress {
     security_groups = ["${aws_security_group.allow_to_cluster.id}"]
     from_port = 0
     to_port = 0
     protocol = "-1"
   }
 }

####################################
######  DEFINITION IAM ROLES  ######
####################################

## SERVICES



#######################################
######  DEFINITION STOCKAGE EFS  ######
#######################################

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

######################################
######  DEFINITION CLUSTER ECS  ######
######################################

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

################################
######  DEFINITION TASKS  ######
################################

data "aws_ecs_task_definition" "gitlab-ce" {
  task_definition = "${aws_ecs_task_definition.gitlab-ce.family}"
}

resource "aws_ecs_task_definition" "gitlab-ce" {
    family                = "CDS-tools"
    container_definitions = <<DEFINITION
[
  {
    "name": "gitlab-ce",
    "image": "gitlab/gitlab-ce:latest",
    "essential": true,
    "portMappings": [
		{
		  "hostPort": 80,
		  "protocol": "tcp",
		  "containerPort": 80
		},
		{
		  "hostPort": 443,
		  "protocol": "tcp",
		  "containerPort": 443
		},
		{
		  "hostPort": 2222,
		  "protocol": "tcp",
		  "containerPort": 22
		}
	  ],
    "memory": 2048,
    "cpu": 2048
  }
]
DEFINITION
}

###################################
######  DEFINITION SERVICES  ######
###################################

resource "aws_ecs_service" "gitlab-ecs-service" {
  	name            = "gitlab-ecs-service"
  	#iam_role        = "${aws_iam_role.ecs-service-role.name}"
  	cluster         = "${aws_ecs_cluster.cluster-main.id}"
  	task_definition = "${aws_ecs_task_definition.gitlab-ce.family}:${max("${aws_ecs_task_definition.gitlab-ce.revision}", "${data.aws_ecs_task_definition.gitlab-ce.revision}")}"
  	desired_count   = 1
}

####################################
######  DEFINITION INSTANCES  ######
####################################

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
