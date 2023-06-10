resource "aws_iam_role" "codepipeline_role" {
  name = "${var.name}-code-pipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_role.json
}

data "aws_iam_policy_document" "codepipeline_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "codepipeline.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    sid = "AllowS3"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:ListBucket",
      "s3:PutObject",
    ]

    resources = [
      var.artifact_bucket_arn,
      "${var.artifact_bucket_arn}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = [ var.code_build_arn ]
  }

  statement {
    sid = "AllowECR"
    effect = "Allow"

    actions = [
      "ecr:*",
    ]

    resources = [
      var.ecr_arn
    ]
  }

  statement {
    sid    = "AllowECS"
    effect = "Allow"

    actions = ["ecs:*"]

    resources = ["*"]
  }

  statement {
    sid    = "AllowPassRole"
    effect = "Allow"

    resources = ["*"]

    actions = ["iam:PassRole"]

    condition {
      test     = "StringLike"
      values   = ["ecs-tasks.amazonaws.com"]
      variable = "iam:PassedToService"
    }
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.name}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id
  policy = "${data.aws_iam_policy_document.codepipeline_policy.json}"
}

resource "aws_iam_role_policy_attachment" "codedeploy_role_attachment" {
  role = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}