output "ec2_instance_id" {
  value = aws_instance.web.id
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "lambda_name" {
  value = aws_lambda_function.remediate.function_name
}

output "lambda_function_url" {
  value = aws_lambda_function_url.remediate_url.function_url
}

output "webhook_example" {
  sensitive = true
  value = <<EOT
curl -i -X POST \
  -H "Content-Type: application/json" \
  -H "X-Shared-Secret: ${var.shared_secret}" \
  -d '{"alert":"api_latency","endpoint":"/api/data","count":6,"window":"10m"}' \
  ${aws_lambda_function_url.remediate_url.function_url}
EOT
}
