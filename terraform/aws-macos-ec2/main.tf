terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "CyrillicIME"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Dedicated Host for macOS (required for mac instances)
resource "aws_ec2_host" "macos_host" {
  instance_type     = var.mac_instance_type
  availability_zone = var.availability_zone

  tags = {
    Name = "cyrillic-ime-macos-host"
  }
}

# Security Group for macOS instance
resource "aws_security_group" "macos_sg" {
  name_description = "Security group for macOS EC2 instance"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks
    description = "SSH access"
  }

  # VNC access (optional, for remote desktop)
  ingress {
    from_port   = 5900
    to_port     = 5900
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks
    description = "VNC access"
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "cyrillic-ime-macos-sg"
  }
}

# IAM Role for EC2 instance
resource "aws_iam_role" "macos_instance_role" {
  name = "cyrillic-ime-macos-instance-role"

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

  tags = {
    Name = "cyrillic-ime-macos-instance-role"
  }
}

# Attach SSM policy for Systems Manager access
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.macos_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile
resource "aws_iam_instance_profile" "macos_profile" {
  name = "cyrillic-ime-macos-profile"
  role = aws_iam_role.macos_instance_role.name
}

# Key pair for SSH access
resource "aws_key_pair" "macos_key" {
  key_name   = "cyrillic-ime-macos-key"
  public_key = var.ssh_public_key

  tags = {
    Name = "cyrillic-ime-macos-key"
  }
}

# User data script for initial setup
data "template_file" "user_data" {
  template = file("${path.module}/user_data.sh")

  vars = {
    github_runner_token = var.github_runner_token
    github_repo_url     = var.github_repo_url
  }
}

# macOS EC2 Instance
resource "aws_instance" "macos" {
  ami           = var.macos_ami_id
  instance_type = var.mac_instance_type
  host_id       = aws_ec2_host.macos_host.id

  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.macos_sg.id]
  key_name                    = aws_key_pair.macos_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.macos_profile.name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "cyrillic-ime-macos-root"
    }
  }

  user_data = data.template_file.user_data.rendered

  tags = {
    Name = "cyrillic-ime-macos-builder"
    Role = "iOS-Builder"
  }

  # macOS instances require minimum 24-hour allocation
  lifecycle {
    ignore_changes = [ami]
  }
}

# Elastic IP for consistent access
resource "aws_eip" "macos_eip" {
  count    = var.use_elastic_ip ? 1 : 0
  instance = aws_instance.macos.id
  domain   = "vpc"

  tags = {
    Name = "cyrillic-ime-macos-eip"
  }
}
