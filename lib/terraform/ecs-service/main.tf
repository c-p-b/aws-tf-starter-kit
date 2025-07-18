data "aws_iam_policy_document" "task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${var.service_name}-task-execution"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role.json
  
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name               = "${var.service_name}-task"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role.json
  
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "task" {
  for_each   = toset(var.task_role_policies != null ? var.task_role_policies : [])
  role       = aws_iam_role.task.name
  policy_arn = each.value
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = var.log_retention_days
  
  tags = var.tags
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.service_name
  requires_compatibilities = [var.launch_type]
  network_mode            = var.launch_type == "FARGATE" ? "awsvpc" : var.network_mode
  cpu                     = var.task_cpu
  memory                  = var.task_memory
  execution_role_arn      = aws_iam_role.task_execution.arn
  task_role_arn           = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name  = var.container_name
    image = var.container_image
    
    cpu    = var.container_cpu
    memory = var.container_memory
    
    essential = true
    
    portMappings = var.port_mappings
    
    environment = [
      for k, v in var.environment_variables : {
        name  = k
        value = v
      }
    ]
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.this.name
        awslogs-region        = data.aws_region.current.name
        awslogs-stream-prefix = "ecs"
      }
    }
    
    healthCheck = var.health_check
  }])
  
  tags = var.tags
}

resource "aws_security_group" "service" {
  count       = var.create_security_group ? 1 : 0
  name        = "${var.service_name}-ecs"
  description = "Security group for ECS service ${var.service_name}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.security_group_rules.ingress
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.service_name}-ecs"
  })
}

resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = var.launch_type

  dynamic "network_configuration" {
    for_each = var.launch_type == "FARGATE" || var.network_mode == "awsvpc" ? [1] : []
    content {
      subnets          = var.subnet_ids
      security_groups  = concat(
        var.create_security_group ? [aws_security_group.service[0].id] : [],
        var.additional_security_groups
      )
      assign_public_ip = var.assign_public_ip
    }
  }

  dynamic "load_balancer" {
    for_each = var.load_balancer_config != null ? [var.load_balancer_config] : []
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = var.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  dynamic "service_registries" {
    for_each = var.service_discovery_config != null ? [var.service_discovery_config] : []
    content {
      registry_arn   = service_registries.value.registry_arn
      port           = lookup(service_registries.value, "port", null)
      container_name = lookup(service_registries.value, "container_name", null)
      container_port = lookup(service_registries.value, "container_port", null)
    }
  }

  enable_execute_command = var.enable_execute_command

  tags = var.tags
}

data "aws_region" "current" {}