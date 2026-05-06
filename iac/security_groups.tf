resource "aws_security_group" "upload_lambda" {
  name        = "upload-lambda-${terraform.workspace}"
  description = "Upload Lambda: solo egress HTTPS"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "HTTPS hacia S3 y SQS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-upload-lambda-${terraform.workspace}"
  }
}

resource "aws_security_group" "crop_lambda" {
  name        = "crop-lambda-${terraform.workspace}"
  description = "Crop Lambda: solo egress HTTPS"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "HTTPS hacia S3 y SQS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-crop-lambda-${terraform.workspace}"
  }
}

resource "aws_security_group" "vpce_sqs" {
  name        = "vpce-sqs-${terraform.workspace}"
  description = "VPC Endpoint SQS: acepta HTTPS solo desde las Lambdas"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Desde upload-lambda"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.upload_lambda.id]
  }

  ingress {
    description     = "Desde crop-lambda"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.crop_lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpce-sqs-${terraform.workspace}"
  }
}