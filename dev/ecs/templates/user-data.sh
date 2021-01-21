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
# According to https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cloudwatch-metrics.html
# ECS metric data is automatically sent to CloudWatch in 1-minute periods. This costs extra money.
# Therefore I'll disable it for now
  echo "ECS_DISABLE_METRICS=true"
} >> /etc/ecs/ecs.config
