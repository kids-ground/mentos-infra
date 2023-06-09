resource "aws_codebuild_project" "codebuild" {
  name = "${var.name}-codebuild-project"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/standard:5.0"
    type = "LINUX_CONTAINER"
    privileged_mode = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "REPOSITORY_URI"
      value = var.ecr_repo_uri
    }
    environment_variable {
      name  = "CONTAINER_NAME"
      value = var.container_name
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = <<BUILDSPEC
${file("${path.module}/buildspec.yml")}
BUILDSPEC
  }
}