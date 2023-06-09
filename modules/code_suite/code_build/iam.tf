resource "aws_iam_role" "codebuild_role" {
  name = "${var.name}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_role.json
}

data "aws_iam_policy_document" "codebuild_role" {
   statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [ "*" ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject"
    ]
    resources = [
      var.artifact_bucket_arn,
      "${var.artifact_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.name}-code-build-policy"
  role = aws_iam_role.codebuild_role.id
  policy = data.aws_iam_policy_document.codebuild_policy.json
}