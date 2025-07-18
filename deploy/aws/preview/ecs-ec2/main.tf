terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
  
  backend "s3" {
    key = "aws/preview/ecs-ec2/terraform.tfstate"
  }
}

module "base" {
  source = "../../../../lib/terraform/deployment-base"
  
  environment  = local.environment
  service      = local.service
  project_name = var.project_name
}

module "ecr_repository" {
  source = "../../../../lib/terraform/ecr-repository"
  
  repository_name = "${module.base.naming_prefix}-ec2"
  
  lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
  
  tags = module.base.common_tags
}

resource "docker_image" "ecs" {
  name = "${module.ecr_repository.repository_url}:latest"
  
  build {
    context    = "../../../../docker/rest-server"
    dockerfile = "Dockerfile.ecs"
    platform   = "linux/amd64"
  }
}

resource "docker_registry_image" "ecs" {
  name = docker_image.ecs.name
  
  depends_on = [module.ecr_repository]
}

data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

module "ecs_cluster" {
  source = "../../../../lib/terraform/ecs-cluster"
  
  cluster_name = "${module.base.naming_prefix}-ec2-cluster"
  
  enable_fargate     = false
  container_insights = true
  
  capacity_providers = [aws_ecs_capacity_provider.this.name]
  
  default_capacity_provider_strategy = [{
    capacity_provider = aws_ecs_capacity_provider.this.name
    weight           = 100
    base             = 0
  }]
  
  tags = module.base.common_tags
}

# IAM role for ECS instances
resource "aws_iam_role" "ecs_instance" {
  name = "${module.base.naming_prefix}-ecs-instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  
  tags = module.base.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_instance_policy" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${module.base.naming_prefix}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance.name
  
  tags = module.base.common_tags
}

# Security group for ECS instances
resource "aws_security_group" "ecs_instances" {
  name        = "${module.base.naming_prefix}-ecs-instances"
  description = "Security group for ECS instances"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Dynamic port range for ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(module.base.common_tags, {
    Name = "${module.base.naming_prefix}-ecs-instances"
  })
}

# Launch template for ECS instances
resource "aws_launch_template" "ecs_instances" {
  name_prefix   = "${module.base.naming_prefix}-ecs-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3.small"
  
  vpc_security_group_ids = [aws_security_group.ecs_instances.id]
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }
  
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    cluster_name = module.ecs_cluster.cluster_name
  }))
  
  tag_specifications {
    resource_type = "instance"
    tags = merge(module.base.common_tags, {
      Name = "${module.base.naming_prefix}-ecs-instance"
    })
  }
  
  tags = module.base.common_tags
}

# Auto Scaling Group
resource "aws_autoscaling_group" "ecs_instances" {
  name                = "${module.base.naming_prefix}-ecs-asg"
  vpc_zone_identifier = module.vpc.public_subnet_ids
  
  min_size         = 1
  max_size         = 3
  desired_capacity = 2
  
  launch_template {
    id      = aws_launch_template.ecs_instances.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "${module.base.naming_prefix}-ecs-asg"
    propagate_at_launch = false
  }
  
  dynamic "tag" {
    for_each = module.base.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }
}

# ECS Capacity Provider
resource "aws_ecs_capacity_provider" "this" {
  name = "tf-starter-${local.environment}-${local.service}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_instances.arn
    
    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 80
    }
    
    managed_termination_protection = "DISABLED"
  }
  
  tags = module.base.common_tags
}

module "vpc" {
  source = "../../../../lib/terraform/aws-network"
  
  name = module.base.naming_prefix
  team = "platform"
  
  aws_network_cidrs = {
    ipv4 = "10.0.0.0/16"
  }
  
  aws_network_subnets = [
    {
      ipv4_cidr_block = "10.0.1.0/24"
      zone            = "us-east-1a"
      public          = true
    },
    {
      ipv4_cidr_block = "10.0.2.0/24"
      zone            = "us-east-1b"
      public          = true
    }
  ]
  
  tags = module.base.common_tags
}

module "alb" {
  source = "../../../../lib/terraform/alb"
  
  name = "${local.environment}-${local.service}-alb"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  
  # Security group for ALB
  security_group_rules = {
    ingress = [{
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP from internet"
    }, {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS from internet"
    }]
  }
  
  # Target group for ECS service
  target_group_config = {
    port        = 8080
    protocol    = "HTTP"
    target_type = "instance"  # Required for EC2 launch type
    health_check = {
      path                = "/health"
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
      interval            = 30
      matcher             = "200"
    }
  }
  
  # Listener configuration
  listeners = [{
    port     = 80
    protocol = "HTTP"
    default_action = {
      type = "forward"
    }
  }]
  
  enable_deletion_protection = false
  
  tags = module.base.common_tags
}

module "ecs_service" {
  source = "../../../../lib/terraform/ecs-service"
  
  service_name    = "${module.base.naming_prefix}-ec2-api"
  cluster_id      = module.ecs_cluster.cluster_id
  launch_type     = "EC2"
  network_mode    = "bridge"
  
  task_cpu    = "256"
  task_memory = "512"
  
  container_name  = "rest-api"
  container_image = "${module.ecr_repository.repository_url}@${docker_registry_image.ecs.sha256_digest}"
  
  port_mappings = [{
    containerPort = 8080
    hostPort      = 0  # Dynamic port mapping for EC2
    protocol      = "tcp"
  }]
  
  environment_variables = {
    ENVIRONMENT     = local.environment
    SERVICE_NAME    = local.service
    PROJECT         = var.project_name
    CONTAINER_TYPE  = "container-ec2"
    PORT            = "8080"
    API_KEY         = random_password.api_key.result
  }
  
  desired_count = 2
  
  # For EC2 launch type with bridge networking, 
  # network configuration is not needed
  create_security_group = false
  
  # Load balancer configuration for public access
  load_balancer_config = {
    target_group_arn = module.alb.target_group_arn
    container_port   = 8080
  }
  
  enable_execute_command = true
  
  tags = module.base.common_tags
}

resource "random_password" "api_key" {
  length  = 32
  special = false
}

locals {
  environment = "preview"
  service     = "ecs-ec2"
}