provider "aws" {
  region = "ap-south-1"
}

############################
# IAM ROLE
############################
resource "aws_iam_role" "lambda_role" {
  name = "lambda_ec2_stop_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

############################
# IAM POLICY
############################
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_ec2_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ec2:StopInstances",
          "ec2:DescribeInstances"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

############################
# ZIP LAMBDA CODE INLINE
############################
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"

  source {
    content  = <<EOF
import boto3

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')

    instance_ids = ['i-1234567890abcdef0']  # replace this

    response = ec2.stop_instances(
        InstanceIds=instance_ids
    )

    return {
        'statusCode': 200,
        'body': str(response)
    }
EOF
    filename = "lambda_function.py"
  }
}

############################
# LAMBDA FUNCTION
############################
resource "aws_lambda_function" "stop_ec2" {
  function_name = "stop-ec2-instance"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role    = aws_iam_role.lambda_role.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.10"

  timeout = 10
}

############################
# OPTIONAL: SCHEDULE (DAILY)
############################
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "stop-ec2-daily"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "StopEC2Lambda"
  arn       = aws_lambda_function.stop_ec2.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_ec2.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}
