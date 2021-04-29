data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.environment}-ecs-task-execution-role-${local.name}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}
resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  name = "${var.environment}-log-group-${local.name}"
  role = aws_iam_role.ecs_task_execution_role.name
  policy = data.aws_iam_policy_document.ecs_task_execution_policy_document.json
}
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  role = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
data "aws_iam_policy_document" "ecs_task_execution_policy_document" {
  statement {
    sid = "AllowCloudWatchLogsCreation"
    actions = [
      "logs:CreateLogGroup",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

# Task container role
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.environment}-ecs-task-role-${local.name}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}
