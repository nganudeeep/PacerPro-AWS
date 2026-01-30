
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}


resource "aws_security_group" "ec2_sg" {
  name        = "pe-codingtest-ec2-sg"
  description = "SG for coding test EC2"
  vpc_id      = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = var.key_name == null ? [] : [1]
    content {
      description = "SSH (optional)"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.ssh_cidr]
    }
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "web" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  key_name = var.key_name

  tags = {
    Name = "pe-codingtest-web"
    App  = "pe-codingtest"
  }
}

resource "aws_sns_topic" "alerts" {
  name = "pe-auto-remediation-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.sns_email_subscription == null ? 0 : 1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.sns_email_subscription
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda_function"
  output_path = "${path.module}/lambda_function.zip"
}


resource "aws_lambda_function" "remediate" {
  function_name = "pe-auto-remediate-ec2"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"
  timeout       = 20

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      INSTANCE_ID   = aws_instance.web.id
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
      SHARED_SECRET = var.shared_secret
    }
  }
}


resource "aws_lambda_function_url" "remediate_url" {
  function_name      = aws_lambda_function.remediate.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "allow_function_url" {
  statement_id           = "AllowPublicInvokeFunctionUrl"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.remediate.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}
