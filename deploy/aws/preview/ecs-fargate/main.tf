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
    key = "aws/preview/ecs-fargate/terraform.tfstate"
    # Other values come from ../../../../backend-config.hcl during init
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
  
  repository_name = "${module.base.naming_prefix}-fargate"
  
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

module "ecs_cluster" {
  source = "../../../../lib/terraform/ecs-cluster"
  
  cluster_name = "${module.base.naming_prefix}-fargate-cluster"
  
  enable_fargate     = true
  container_insights = true
  
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  
  default_capacity_provider_strategy = [{
    capacity_provider = "FARGATE_SPOT"
    weight           = 80
    base             = 0
  }, {
    capacity_provider = "FARGATE"
    weight           = 20
    base             = 0
  }]
  
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
      public          = false
    },
    {
      ipv4_cidr_block = "10.0.2.0/24"
      zone            = "us-east-1b"
      public          = false
    },
    {
      ipv4_cidr_block = "10.0.101.0/24"
      zone            = "us-east-1a"
      public          = true
    },
    {
      ipv4_cidr_block = "10.0.102.0/24"
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
    target_type = "ip"  # Required for Fargate with awsvpc network mode
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
  
  service_name    = "${module.base.naming_prefix}-fargate-api"
  cluster_id      = module.ecs_cluster.cluster_id
  launch_type     = "FARGATE"
  network_mode    = "awsvpc"
  
  task_cpu    = "256"
  task_memory = "512"
  
  container_name  = "rest-api"
  container_image = "${module.ecr_repository.repository_url}@${docker_registry_image.ecs.sha256_digest}"
  
  port_mappings = [{
    containerPort = 8080
    hostPort      = 8080
    protocol      = "tcp"
  }]
  
  environment_variables = {
    ENVIRONMENT     = local.environment
    SERVICE_NAME    = local.service
    PROJECT         = var.project_name
    CONTAINER_TYPE  = "ecs-fargate"
    PORT            = "8080"
    API_KEY         = random_password.api_key.result
  }
  
  desired_count = 2
  
  # Fargate requires network configuration
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.public_subnet_ids
  assign_public_ip = true
  
  create_security_group = true
  security_group_rules = {
    ingress = [{
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
      description = "HTTP traffic from ALB"
    }]
  }
  
  enable_execute_command = true
  
  # Load balancer configuration for public access
  load_balancer_config = {
    target_group_arn = module.alb.target_group_arn
    container_port   = 8080
  }
  
  tags = module.base.common_tags
}

resource "random_password" "api_key" {
  length  = 32
  special = false
}

locals {
  environment = "preview"
  service     = "ecs-fargate"
}