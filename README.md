# typescript-lambda-terraform

A example of the hurdles to so through to build a typescript lambda using the standard  terraform [terraform-aws-lambda](https://github.com/terraform-aws-modules/terraform-aws-lambda.git) module.

Most of the heavy lifting is done via a Makefile based build - Idempotent building is provided by separate hashing of the lambda source directory.

Uses local TF state and only for demo purposes.

