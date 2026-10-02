data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [var.trusted_service]
    }
  }
}

resource "aws_iam_role" "role" {
  name               = local.role_name
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "permissions" {
    count = length(var.policy_statements) > 0 ? 1 : 0

    dynamic "statement" {
        for_each = var.policy_statements
        content {
            sid = statement.value.sid
            effect = "Allow"
            actions = statement.value.actions
            resources = statement.value.resources
        }
    }
}

resource "aws_iam_policy" "policy" {
    count = length(var.policy_statements) > 0 ? 1 : 0
    name = "${local.role_name}-policy"
    policy = data.aws_iam_policy_document.permissions[0].json
    tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "custom" {
    count = length(var.policy_statements) > 0 ? 1 : 0
    role = aws_iam_role.role.name
    policy_arn = aws_iam_policy.policy[0].arn
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = toset(var.managed_policy_arns)
  role       = aws_iam_role.role.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "instance" {
  count = var.trusted_service == "ec2.amazonaws.com" ? 1 : 0
  name  = local.role_name
  role  = aws_iam_role.role.name
  tags  = local.common_tags
}