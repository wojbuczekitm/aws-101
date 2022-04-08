terraform_state = {
  bucket = "wb-code-bucket"
  key    = "tf/terraform.tfstate"
}

namespace = "wb"
stage     = "main"
name      = "hello-world"


codebuild_iam_policy_arns = [
  "arn:aws:iam::aws:policy/AWSLambdaFullAccess",
  "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
  "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess",
  "arn:aws:iam::aws:policy/IAMFullAccess",
]

codepipeline_iam_policy_arns = [
  "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
]
