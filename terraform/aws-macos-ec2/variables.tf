variable "aws_region" {
  description = "AWS region for macOS EC2 instance"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "availability_zone" {
  description = "Availability zone for dedicated host"
  type        = string
  default     = "us-east-1a"
}

variable "mac_instance_type" {
  description = "macOS instance type (mac1.metal or mac2.metal)"
  type        = string
  default     = "mac2.metal"

  validation {
    condition     = contains(["mac1.metal", "mac2.metal"], var.mac_instance_type)
    error_message = "Instance type must be mac1.metal or mac2.metal"
  }
}

variable "macos_ami_id" {
  description = "AMI ID for macOS (Monterey, Ventura, or Sonoma)"
  type        = string
  # Example: ami-0c55b159cbfafe1f0 (macOS Sonoma 14.x in us-east-1)
  # You need to find the latest AMI ID in your region
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID where instance will be launched"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for macOS instance"
  type        = string
}

variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH into the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"] # CHANGE THIS to your IP for security
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 200
}

variable "use_elastic_ip" {
  description = "Whether to allocate an Elastic IP"
  type        = bool
  default     = true
}

variable "github_runner_token" {
  description = "GitHub Actions self-hosted runner registration token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "github_repo_url" {
  description = "GitHub repository URL for self-hosted runner"
  type        = string
  default     = "https://github.com/clearclown/cyrillicJapaneseInput"
}
