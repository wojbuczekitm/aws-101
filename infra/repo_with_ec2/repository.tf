resource "aws_ecr_repository" "repository" {
  name = "${var.resource_prefix}-repository"
}

resource "aws_ecr_repository_policy" "single_repository_policy" {
  repository = aws_ecr_repository.repository.name
  policy     = <<EOF
  {
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetLifecyclePolicy",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer"
        ]
      }
    ]
  }
  EOF
}
