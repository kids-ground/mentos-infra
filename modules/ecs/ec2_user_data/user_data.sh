#!/bin/bash

# Update all packages
sudo yum update -y
sudo amazon-linux-extras disable docker
sudo amazon-linux-extras install -y ecs

# Adding cluster name in ecs config
sudo mkdir -p /etc/ecs && sudo touch /etc/ecs/ecs.config
sudo echo ECS_CLUSTER=mentos-ecs-cluster >> /etc/ecs/ecs.config
cat /etc/ecs/ecs.config | grep "ECS_CLUSTER"

# Start ECS Agent
sudo systemctl enable --now ecs