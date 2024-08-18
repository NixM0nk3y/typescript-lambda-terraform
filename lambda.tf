data "aws_iam_policy_document" "lambda_perms" {
  statement {
    sid    = "AllowSSM"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    # access to API params
    #tfsec:ignore:aws-iam-no-policy-wildcards
    resources = [
      "arn:aws:ssm:${local.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.tenant}/${var.product}}/${local.environment}/*",
    ]
  }
}

#
# Track source changes to the lambda
#
locals {
  source_directory       = "${path.cwd}/resources/sample"
  source_directory_files = fileset(local.source_directory, "**")
  source_file_hashes = {
    for path in local.source_directory_files :
    path => filebase64sha512("${local.source_directory}/${path}")
  }
  overall_hash = base64sha512(jsonencode(local.source_file_hashes))
}

module "sample_lambda" {
  source = "./vendor/modules/terraform-aws-lambda"

  function_name = "${module.this.id}-sample"
  description   = "Sample Lambda"
  handler       = "lambda.lambdaHandler"
  runtime       = "nodejs20.x"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory
  architectures = ["arm64"]

  build_in_docker = true
  docker_additional_options = [
    "-e", "AWS_ACCESS_KEY_ID",
    "-e", "AWS_SECRET_ACCESS_KEY",
    "-e", "AWS_SESSION_TOKEN",
    "-e", "COMMIT", # build vars to pass into the lamdba (as it doesn't contain the full git checkout)
    "-e", "BRANCH",
    "-e", "DATE",
    "-e", "REGION=${local.aws_region}",
    "-v", "${path.cwd}/lambda-builder:/entrypoint:ro",
    "-v", "${path.cwd}/resources/sample:/code:ro",
  ]

  # use docker builds
  docker_entrypoint = "/entrypoint/entrypoint.sh"
  docker_file       = "${path.cwd}/lambda-builder/nodejs20_x86.dockerfile"
  docker_image      = "${module.this.id}-nodejs20-x86-build"

  # only package the bundled lambda
  source_path = [
    {
      path             = "${path.cwd}/resources/sample"
      npm_package_json = true
      patterns         = <<END
            !.*
            lambda.mjs
          END
    }
  ]

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.lambda_perms.json

  tracing_mode          = "Active"
  attach_tracing_policy = true

  cloudwatch_logs_retention_in_days = var.log_retention

  create_current_version_allowed_triggers = false

  environment_variables = {
    LOG_LEVEL   = "INFO"
    TENANT      = var.tenant
    ENVIRONMENT = local.environment
    PRODUCT     = var.product
  }

  recreate_missing_package = false
  ignore_source_code_hash  = true
  # trigger build on source changes
  hash_extra = local.overall_hash
}
