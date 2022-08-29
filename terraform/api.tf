locals {
  http-lib-filename = "../backend/http-lib/dist/bundle.zip"
  toggles-filename  = "../backend/feature-toggles/dist/bundle.zip"
}

resource "aws_lambda_function" "toggles" {
  function_name = "toggles"
  role          = aws_iam_role.toggles.arn

  filename         = local.toggles-filename
  handler          = "feature_toggles.handler.get_toggles"
  source_code_hash = filebase64sha256(local.toggles-filename)
  layers           = [aws_lambda_layer_version.http-lib.arn]

  runtime = "python3.9"
}

resource "aws_lambda_function_url" "toggles" {
  function_name      = aws_lambda_function.toggles.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "toggles" {
  statement_id_prefix = "AllowAccessFromApiGateway-"

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.toggles.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/GET/*"
}

resource "aws_lambda_layer_version" "http-lib" {
  layer_name = "http-lib"

  filename         = local.http-lib-filename
  source_code_hash = filebase64sha256(local.http-lib-filename)

  compatible_runtimes = ["python3.9"]
}

data "aws_iam_policy_document" "lambda_function_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "toggles" {
  assume_role_policy = data.aws_iam_policy_document.lambda_function_assume_role.json
}

resource "aws_iam_role_policy_attachment" "toggles" {
  role       = aws_iam_role.toggles.name
  policy_arn = aws_iam_policy.read-toggles.arn
}

resource "aws_api_gateway_rest_api" "api" {
  name = "API"
  body = templatefile("../backend/openapi.yaml", {
    toggles-arn = aws_lambda_function.toggles.invoke_arn,
  })
}

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    api-description = sha256(aws_api_gateway_rest_api.api.body)
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api.id
  stage_name    = "default"
}
