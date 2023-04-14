variable "cluster_name" {
  type = string
  description = "Cluster Name"
  default = "nginx-ecs-app"
}

variable "aws_region" {
  type = string
  description = "Region"
  default = "us-east-1"
}