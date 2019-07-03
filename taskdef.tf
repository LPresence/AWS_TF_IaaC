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
