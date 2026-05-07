output "api_endpoint" {
  description = "URL publica del endpoint. Usa esta para hacer POST /upload"
  value       = "${aws_apigatewayv2_stage.default.invoke_url}/upload"
}

output "s3_bucket_name" {
  description = "Nombre del bucket S3"
  value       = aws_s3_bucket.images.bucket
}

output "upload_lambda_name" {
  description = "Nombre de la funcion Lambda de subida"
  value       = aws_lambda_function.upload.function_name
}

output "crop_lambda_name" {
  description = "Nombre de la funcion Lambda de recorte"
  value       = aws_lambda_function.crop.function_name
}

output "sqs_queue_url" {
  description = "URL de la cola SQS principal"
  value       = aws_sqs_queue.main.id
}

output "sqs_dlq_url" {
  description = "URL de la Dead-Letter Queue"
  value       = aws_sqs_queue.dlq.id
}

output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "workspace" {
  description = "Entorno actualmente desplegado"
  value       = terraform.workspace
}