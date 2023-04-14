# # IAM Role
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${var.cluster_name}-execution-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags = {
    Name        = "${var.cluster_name}-iam-role"
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# CloudWatch Log group
resource "aws_cloudwatch_log_group" "log-group" {
  name = "${var.cluster_name}-logs"
  tags = {
    Application = var.cluster_name
  }
}

resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = var.cluster_name
  tags = {
    Name        = var.cluster_name
  }
}

# Task Defination
resource "aws_ecs_task_definition" "aws-ecs-task" {
  family = "${var.cluster_name}-nginx-task"
  container_definitions = <<DEFINITION
  [
    {
      "name": "${var.cluster_name}-nginx-container",
      "image": "cloudmagicmaster/nginx:1.1",
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.log-group.id}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "${var.cluster_name}"
        }
      },
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ],
      "cpu": 256,
      "memory": 512,
      "networkMode": "awsvpc"
    }
  ]
  DEFINITION

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn

  tags = {
    Name        = "${var.cluster_name}-td"
  }
}

data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.aws-ecs-task.family
}

#Security Group
resource "aws_security_group" "service_security_group" {
  vpc_id = "vpc-0f27b8fe4a7ac492c"
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.cluster_name}-service-sg"
  }
}

# Task Service
resource "aws_ecs_service" "aws-ecs-service" {
  name                 = "${var.cluster_name}-service"
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = "${aws_ecs_task_definition.aws-ecs-task.family}:${max(aws_ecs_task_definition.aws-ecs-task.revision, data.aws_ecs_task_definition.main.revision)}"
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    subnets          = ["subnet-0ee719433e9ce8ecb","subnet-09841d44cdc9cddc8"]
    assign_public_ip = true
    security_groups = [
      aws_security_group.service_security_group.id,
    #   aws_security_group.load_balancer_security_group.id
    ]
  }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.target_group.arn
#     container_name   = "${var.cluster_name}-${var.app_environment}-container"
#     container_port   = 8080
#   }

#  depends_on = [aws_lb_listener.listener]
}