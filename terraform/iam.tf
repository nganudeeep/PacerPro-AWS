resource "aws_iam_role" "lambda_role" {
  name = "pe-codingtest-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}


resource "aws_iam_policy" "lambda_policy" {
  name = "pe-codingtest-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },

      {
        Effect   = "Allow",
        Action   = ["sns:Publish"],
        Resource = aws_sns_topic.alerts.arn
      },

      {
        Effect = "Allow",
        Action = ["ec2:RebootInstances"],
        Resource = "*",
        Condition = {
          StringEquals = {
            "aws:ResourceTag/App" = "pe-codingtest"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
