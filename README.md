# PacerPro-AWS
This project implements a basic auto-remediation flow for handling application latency issues.

A log query is defined to detect slow responses on the /api/data endpoint. If repeated slow requests are observed within a short time window, an alert is triggered.

The alert is designed to invoke an AWS Lambda function through an HTTP webhook. The Lambda function restarts a specific EC2 instance and sends a notification through SNS, while logging all actions for visibility.

All required AWS resources, including the EC2 instance, Lambda function, SNS topic, and IAM permissions, are provisioned using Terraform. The setup can be tested by triggering the Lambda endpoint and verifying the EC2 reboot and SNS notification.

curl -i -X POST \
  -H "Content-Type: application/json" \
  -H "X-Shared-Secret: abc123" \
  -d '{"alert":"api_latency","endpoint":"/api/data","count":6,"window":"10m"}' \
  <Functional_URL>

