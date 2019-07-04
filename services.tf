resource "aws_ecs_service" "gitlab-ecs-service" {
  name = "gitlab-ecs-service"
  #iam_role        = "${aws_iam_role.ecs-service-role.name}"
  cluster         = "${aws_ecs_cluster.cluster-main.id}"
  task_definition = "${aws_ecs_task_definition.gitlab-ce.family}:${max("${aws_ecs_task_definition.gitlab-ce.revision}", "${data.aws_ecs_task_definition.gitlab-ce.revision}")}"
  desired_count   = 1
}