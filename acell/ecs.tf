resource "aws_cloudwatch_log_group" "logging-api-log-group" {
  name  = module.label.id

  retention_in_days = 14
}

resource "aws_ecr_repository" "logging-api-ecr" {
  name  = module.label.id
}

resource "aws_ecs_task_definition" "logging-api-task" {
  family                   = "logging-api-task-${module.label.id}"
  task_role_arn            = aws_iam_role.logging-api-task-role.arn
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = "arn:aws:iam::261219435789:role/ecsTaskExecutionRole"
  memory                   = 512
  cpu                      = "256"
  network_mode             = "awsvpc"

  container_definitions = <<EOF
[
    {
      "volumesFrom": [],
      "memory": 512,
      "extraHosts": null,
      "dnsServers": null,
      "disableNetworking": null,
      "dnsSearchDomains": null,
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ],
      "hostname": null,
      "essential": true,
      "entryPoint": null,
      "mountPoints": [],
      "name": "logging",
      "ulimits": null,
      "dockerSecurityOptions": null,
      "environment": [],
      "links": null,
      "workingDirectory": null,
      "readonlyRootFilesystem": null,
      "image": "nginxdemos/hello",
      "command": null,
      "user": null,
      "dockerLabels": null,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.logging-api-log-group.name}",
          "awslogs-region": "${data.aws_region.current.name}",
          "awslogs-stream-prefix": "${module.label.id}"
        }
      },
      "cpu": 0,
      "privileged": null,
      "expanded": true
    }
]
EOF
}

resource "aws_ecs_cluster" "api-cluster" {
  name = module.label.id
}

//do not use this in prodution
resource "aws_security_group" "stupid_dangrous_sg" {

  vpc_id = module.networking.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = module.label.tags
}

data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

module "networking" {
  source          = "cn-terraform/networking/aws"
  version         = "2.0.3"
  name_preffix    = module.label.id
  region          = data.aws_region.current.name
  profile         = "aws_profile"
  vpc_cidr_block  = "192.168.0.0/16"
  availability_zones                          =  data.aws_availability_zones.available.names
  public_subnets_cidrs_per_availability_zone  = [ "192.168.0.0/19", "192.168.32.0/19", "192.168.64.0/19", "192.168.96.0/19" ]
  private_subnets_cidrs_per_availability_zone = [ "192.168.128.0/19", "192.168.160.0/19", "192.168.192.0/19", "192.168.224.0/19" ]
}

resource "aws_ecs_service" "logging-api-service" {
  name            = "logging-api-service-${module.label.id}"
  cluster         = aws_ecs_cluster.api-cluster.id
  task_definition = aws_ecs_task_definition.logging-api-task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [
      aws_security_group.stupid_dangrous_sg.id,
    ]

    subnets          = module.networking.public_subnets_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.logging-api-tg.arn
    container_name   = "logging"
    container_port   = "80"
  }
}

resource "aws_alb_target_group" "logging-api-tg" {
  depends_on  = ["aws_lb.lb"]
  name        = "logging-api-${module.label.id}"
  port        = "80"
  protocol    = "HTTP"
  vpc_id      = module.networking.vpc_id
  target_type = "ip"

  tags = {
    Name = "logging-api-tg-${module.label.id}"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    path                = "/healthcheck"
  }
}

resource "aws_lb" "lb" {
  load_balancer_type = "application"

  name = module.label.id
  security_groups = [aws_security_group.stupid_dangrous_sg.id]
  subnets = module.networking.public_subnets_ids

  enable_cross_zone_load_balancing = true
  internal = false
}

resource "aws_alb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn

  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.logging-api-tg.arn
  }
}

resource "aws_iam_role" "logging-api-task-role" {
  name  = "${module.label.id}-logging-api-task-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
