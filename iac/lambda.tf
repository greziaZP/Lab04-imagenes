data "archive_file" "upload" {
  type        = "zip"
  source_dir  = "${path.module}/../src/upload"
  output_path = "${path.module}/../.build/upload.zip"
}

data "archive_file" "crop" {
  type        = "zip"
  source_dir  = "${path.module}/../src/crop"
  output_path = "${path.module}/../.build/crop.zip"
}

resource "aws_lambda_function" "upload" {
  function_name    = "image-processor-${terraform.workspace}-upload"
  description      = "Recibe imagenes via HTTP y las guarda en S3 uploads/"
  filename         = data.archive_file.upload.output_path
  source_code_hash = data.archive_file.upload.output_base64sha256
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  role             = aws_iam_role.upload_lambda.arn
  memory_size      = var.upload_memory[terraform.workspace]
  timeout          = var.upload_timeout[terraform.workspace]

  environment {
    variables = {
      S3_BUCKET     = aws_s3_bucket.images.bucket
      UPLOAD_PREFIX = "uploads/"
      ENVIRONMENT   = terraform.workspace
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.upload_lambda.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.upload_basic,
    aws_iam_role_policy_attachment.upload_vpc,
    aws_cloudwatch_log_group.upload
  ]

  tags = {
    Name = "image-processor-${terraform.workspace}-upload"
  }
}

resource "aws_lambda_function" "crop" {
  function_name    = "image-processor-${terraform.workspace}-crop"
  description      = "Lee SQS, recorta imagen a 40x40 circular, guarda en S3"
  filename         = data.archive_file.crop.output_path
  source_code_hash = data.archive_file.crop.output_base64sha256
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  role             = aws_iam_role.crop_lambda.arn
  memory_size      = var.crop_memory[terraform.workspace]
  timeout          = var.crop_timeout[terraform.workspace]

  environment {
    variables = {
      S3_BUCKET        = aws_s3_bucket.images.bucket
      PROCESSED_PREFIX = "processed/"
      ENVIRONMENT      = terraform.workspace
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.crop_lambda.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.crop_basic,
    aws_iam_role_policy_attachment.crop_vpc,
    aws_cloudwatch_log_group.crop
  ]

  tags = {
    Name = "image-processor-${terraform.workspace}-crop"
  }
}

resource "aws_lambda_event_source_mapping" "sqs_to_crop" {
  event_source_arn                   = aws_sqs_queue.main.arn
  function_name                      = aws_lambda_function.crop.arn
  batch_size                         = 5
  maximum_batching_window_in_seconds = 5
  function_response_types            = ["ReportBatchItemFailures"]

  depends_on = [aws_iam_role_policy.crop_sqs]
}