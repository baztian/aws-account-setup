# ECS cluster setup

In order to destroy this ECS cluster you'll need to destroy all ECS services
first. This is due to [a bug in terraform](
https://github.com/hashicorp/terraform-provider-aws/issues/4852). Also you need stop the instances from the ASG.

    ASG_NAME=$(terraform output -raw asg_name)
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME --min-size 0 --desired-capacity 0
