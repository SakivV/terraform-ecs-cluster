# ECS Cluster using Terraform
## What is ECS ?
AWS ECS (Elastic Container Service) is a fully-managed container orchestration service provided by Amazon Web Services (AWS). It allows you to easily run and manage Docker containers on a cluster of EC2 instances, and it offers features such as automatic scaling, load balancing, and service discovery. With ECS, you can build scalable and fault-tolerant applications without having to manage the underlying infrastructure yourself.

## Create ECS Cluster using Terraform

1. Using this repo, we would be create ECS Cluster (Fargate based) using Terraform.
2. In this repo, below values are hardcode, which you need to modify:
   1. VPC-ID
   2. Subnets
   3. Image : This Docker Hub image URL