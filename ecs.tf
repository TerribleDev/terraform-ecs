
resource "aws_ecr_repository" "registry" {
  name = "${var.container_name}"
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.container_name}"
}

resource "aws_launch_configuration" "ecs" {
  name                 = "ecs-${aws_ecr_repository.registry.name}"
  /*this is the ami for aws irl, we should probably take this as a var or have a map of all the images*/
  image_id             = "ami-48f9a52e"
  instance_type        = "m3.medium"
  iam_instance_profile = "${aws_iam_instance_profile.ecs.id}"
  security_groups      = ["${aws_security_group.allow_all.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.ecs.name}"
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=${aws_ecr_repository.cluster.name} > /etc/ecs/ecs.config"
}

/**
 * Autoscaling group.
 */
resource "aws_autoscaling_group" "ecs" {
  name                 = "ecs-asg"
  /* @todo take subnets as either 1 list arg or maybe some other way?*/
  vpc_zone_identifier = ["${var.SubnetPrivate1a}", "${var.SubnetPrivate1b}", "${var.SubnetPrivate1c}"]
  launch_configuration = "${aws_launch_configuration.ecs.name}"
  /* @todo - variablize */
  min_size             = 1
  max_size             = 10
  desired_capacity     = 3
}


data "template_file" "task-definitions" {
    template = "${file("task-definitions/tasks.json")}"

    vars {
        registry = "${var.account_id}.dkr.ecr.eu-west-1.amazonaws.com/${aws_ecr_repository.registry.name}"
        container_name = "${var.container_name}"
        container_port = "${var.container_port}"
        host_port = "${var.host_port}"
    }
}

output "rendered" {
  value = "${data.template_file.task-definitions.rendered}"
}

resource "aws_ecs_task_definition" "main_task_definition" {
  family = "${var.container_name}"
  container_definitions = "${data.template_file.task-definitions.rendered}"
}

resource "aws_ecs_service" "main-service" {
  name            = "${var.container_name}-service"
  cluster         = "${aws_ecr_repository.cluster.id}"
  iam_role = "${aws_iam_role.ecs_service_role.arn}"
  depends_on = ["aws_iam_role_policy.ecs_service_role_policy"]
  task_definition = "${aws_ecs_task_definition.main_task_definition.arn}"
  desired_count   = 1
      load_balancer {
        elb_name = "${aws_elb.elb-http.id}"
        container_name = "${var.container_name}"
        container_port = "${var.host_port}"
    }
}


resource "aws_elb" "elb-http" {
    name = "${var.container_name}-elb"
    security_groups = ["${aws_security_group.allow_all.id}"]
    subnets = ["${var.SubnetPublic1a}","${var.SubnetPublic1b}","${var.SubnetPublic1c}"]

    listener {
        lb_protocol = "http"
        lb_port = "${var.lb_port}"

        instance_protocol = "http"
        instance_port = "${var.host_port}"
    }
    /* uncomment for livecheck, todo variable-ize */
  /*
    health_check {
        healthy_threshold = 3
        unhealthy_threshold = 2
        timeout = 3
        target = "HTTP:${var.lb_port}/livecheck"
        interval = 5
    }
*/
    cross_zone_load_balancing = true
}


