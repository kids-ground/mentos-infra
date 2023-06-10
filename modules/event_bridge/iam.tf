resource "aws_iam_role" "eventbridge_codepipeline_role" {
  name = "${var.name}-eventbridge-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_codepipeline_role.json
}

data "aws_iam_policy_document" "eventbridge_codepipeline_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_policy" "eventbridge_codepipeline_policy" {
  name = "${var.name}-eventbridge-codepipeline-policy"
  policy = data.aws_iam_policy_document.eventbridge_codepipeline_policy.json
}

data "aws_iam_policy_document" "eventbridge_codepipeline_policy" {
  statement {
    sid = "AllowStartPipeline"
    effect = "Allow"
    actions = [
      "codepipeline:StartPipelineExecution"
    ]
    resources = [ 
      var.codepipeline_arn
    ]
  }
}

resource "aws_iam_role_policy_attachment" "eventbridge_codepipeline_policy_attachment" {
  role       = aws_iam_role.eventbridge_codepipeline_role.name
  policy_arn = aws_iam_policy.eventbridge_codepipeline_policy.arn
}