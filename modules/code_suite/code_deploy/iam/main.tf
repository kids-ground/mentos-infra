resource "aws_iam_role" "codedeploy_role" {
  name = "${var.name}-codedeploy-role"
  assume_role_policy = data.aws_iam_policy_document.codedeploy_role.json
}

data "aws_iam_policy_document" "codedeploy_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "codedeploy.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "codedeploy_role_attachment" {
  role = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}