#!/bin/bash

# Setup 2 GB swap file
# https://aws.amazon.com/premiumsupport/knowledge-center/ec2-memory-swap-file/
dd if=/dev/zero of=/swapfile bs=128M count=16
chmod 600 /swapfile
mkswap /swapfile
echo /swapfile swap swap defaults 0 0 >> /etc/fstab
swapon -a

# ECS config
# see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-config.html
{
  echo "ECS_CLUSTER=${cluster_name}"
  echo "ECS_DISABLE_METRICS=${disable_metrics}"
} >> /etc/ecs/ecs.config

${additional_user_data}
