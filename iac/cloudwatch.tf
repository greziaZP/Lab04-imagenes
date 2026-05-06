resource "aws_cloudwatch_log_group" "upload" {
  name              = "/aws/lambda/image-processor-${terraform.workspace}-upload"
  retention_in_days = var.log_retention_days[terraform.workspace]

  tags = {
    Name = "logs-upload-${terraform.workspace}"
  }
}

resource "aws_cloudwatch_log_group" "crop" {
  name              = "/aws/lambda/image-processor-${terraform.workspace}-crop"
  retention_in_days = var.log_retention_days[terraform.workspace]

  tags = {
    Name = "logs-crop-${terraform.workspace}"
  }
}

resource "aws_cloudwatch_log_group" "apigw" {
  name              = "/aws/apigateway/image-processor-${terraform.workspace}"
  retention_in_days = var.log_retention_days[terraform.workspace]

  tags = {
    Name = "logs-apigw-${terraform.workspace}"
  }
}

resource "aws_cloudwatch_metric_alarm" "dlq_alarm" {
  alarm_name          = "dlq-messages-alarm-${terraform.workspace}"
  alarm_description   = "Hay mensajes en la DLQ de ${terraform.workspace} - revisar logs de crop-lambda"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }

  tags = {
    Name = "dlq-alarm-${terraform.workspace}"
  }
}