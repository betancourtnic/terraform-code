# -----------------------------------------------------------------------------
# AWS Provider Configuration
# -----------------------------------------------------------------------------
# Defines the AWS provider and the region for resource deployment.
# OpenTofu will automatically pick up credentials configured via AWS CLI.
# -----------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region
}


# -----------------------------------------------------------------------------
# Input Variables
# Define customizable parameters for your S3 bucket.
# -----------------------------------------------------------------------------
variable "aws_region" {
  description = "The AWS region where resources will be deployed."
  type        = string
  default     = "us-east-1" # Set your preferred default region here
}

variable "bucket_name_prefix" {
  description = "A unique prefix for your S3 bucket name. A random string will be appended."
  type        = string
  default     = "my-opentofu-bucket"
}

variable "environment" {
  description = "The environment the bucket belongs to (e.g., dev, qa, prod)."
  type        = string
  default     = "dev"
}

variable "enable_versioning" {
  description = "Set to true to enable versioning for the bucket."
  type        = bool
  default     = true
}

variable "enable_server_access_logging" {
  description = "Set to true to enable server access logging for the bucket."
  type        = bool
  default     = false # Set to true to enable logging
}

variable "log_bucket_name" {
  description = "The name of the bucket where access logs will be delivered (if enabled). Must exist."
  type        = string
  default     = "my-s3-logs-bucket-1234567890" # Change this to a real, existing log bucket
}

# -----------------------------------------------------------------------------
# Local Values
# Intermediate values for better readability and reusability within the config.
# -----------------------------------------------------------------------------
locals {
  # Generate a unique suffix for the bucket name to ensure global uniqueness.
  # This makes it easy to create multiple buckets without naming conflicts.
  unique_suffix = substr(md5(uuid()), 0, 8) # Using uuid() for more uniqueness
  full_bucket_name = "${var.bucket_name_prefix}-${local.unique_suffix}"
}

# -----------------------------------------------------------------------------
# S3 Bucket Resource Definition
# -----------------------------------------------------------------------------
# Defines the primary S3 bucket.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "example_bucket" {
  # S3 bucket names must be globally unique across ALL AWS accounts.
  # Using a prefix from var.bucket_name_prefix and a unique suffix ensures this.
  bucket = local.full_bucket_name

  # Enable versioning for data protection (highly recommended)
  versioning {
    enabled = var.enable_versioning
  }

  # Enable server access logging (recommended for auditing)
  # IMPORTANT: The log_bucket_name must refer to an existing S3 bucket
  #            where logs will be stored. This log bucket should ideally have
  #            its own public access block and potentially different settings.
  #            If 'enable_server_access_logging' is true, this section
  #            MUST refer to a valid, pre-existing bucket for logs.
  dynamic "logging" {
    for_each = var.enable_server_access_logging ? [1] : []
    content {
      target_bucket = var.log_bucket_name
      target_prefix = "s3-access-logs/${local.full_bucket_name}/"
    }
  }

  # Add common tags for organization and cost allocation.
  tags = {
    Name        = "OpenTofu-${var.environment}-Bucket"
    Environment = var.environment
    Project     = "OpenTofuGuide"
  }
}

# -----------------------------------------------------------------------------
# S3 Public Access Block Configuration
# -----------------------------------------------------------------------------
# This resource explicitly blocks all public access to the S3 bucket.
# This is a critical security best practice for private buckets.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "example_bucket_public_access_block" {
  bucket = aws_s3_bucket.example_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# Output Values
# Display important information about the deployed S3 bucket.
# -----------------------------------------------------------------------------
output "bucket_name" {
  description = "The globally unique name of the S3 bucket."
  value       = aws_s3_bucket.example_bucket.bucket
}

output "bucket_arn" {
  description = "The Amazon Resource Name (ARN) of the S3 bucket."
  value       = aws_s3_bucket.example_bucket.arn
}

output "bucket_id" {
  description = "The ID of the S3 bucket."
  value       = aws_s3_bucket.example_bucket.id
}
