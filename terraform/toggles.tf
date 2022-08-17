resource "aws_ssm_parameter" "new-feature-1" {
  name  = "/toggles/new-feature-1"
  value = "false"
  type  = "String"

  overwrite = false

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_iam_policy" "read-toggles" {
  name_prefix = "read-toggles-"
  policy      = data.aws_iam_policy_document.read-toggles.json
}

data "aws_iam_policy_document" "read-toggles" {
  statement {
    actions   = ["ssm:GetParametersByPath"]
    resources = ["arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/toggles/*"]
  }
}
