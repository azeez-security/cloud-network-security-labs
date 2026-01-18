########################################
# SOAR Dispatcher Lambda
########################################

resource "aws_iam_role" "soar_lambda_role" {
  count = var.enable_soar ? 1 : 0
  name  = "${var.project_name}-soar-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "soar_lambda_policy" {
  count = var.enable_soar ? 1 : 0
  name  = "${var.project_name}-soar-lambda-policy"
  role  = aws_iam_role.soar_lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat(
      [
        # CloudWatch Logs
        {
          Effect = "Allow",
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource = "*"
        },

        # Optional response actions (least privilege baseline)
        {
          Effect = "Allow",
          Action = [
            "securityhub:BatchUpdateFindings",
            "securityhub:GetFindings"
          ],
          Resource = "*"
        }
      ],

      # Evidence bucket write
      (var.enable_soar_evidence_s3 && var.soar_evidence_bucket_name != "") ? [
        {
          Effect   = "Allow",
          Action   = ["s3:PutObject"],
          Resource = "arn:aws:s3:::${var.soar_evidence_bucket_name}/*"
        }
      ] : [],

      # EC2 quarantine + snapshot actions (only if enabled)
      (var.enable_soar_ec2_quarantine || var.enable_soar_snapshot) ? [
        {
          Effect = "Allow",
          Action = [
            "ec2:DescribeInstances",
            "ec2:DescribeVolumes",
            "ec2:DescribeTags",
            "ec2:ModifyInstanceAttribute",
            "ec2:CreateSnapshot",
            "ec2:DescribeSnapshots"
          ],
          Resource = "*"
        }
      ] : [],

      # IAM disable actions (only if enabled)
      (var.enable_soar_iam_disable) ? [
        {
          Effect = "Allow",
          Action = [
            "iam:GetUser",
            "iam:ListAccessKeys",
            "iam:UpdateAccessKey"
          ],
          Resource = "*"
        }
      ] : []
    )
  })
}

resource "aws_lambda_function" "soar_dispatcher" {
  count         = var.enable_soar ? 1 : 0
  function_name = "${var.project_name}-soar-dispatcher"
  role          = aws_iam_role.soar_lambda_role[0].arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60
  memory_size   = 128

  filename         = data.archive_file.soar_lambda_zip.output_path
  source_code_hash = data.archive_file.soar_lambda_zip.output_base64sha256

  environment {
    variables = {
      PROJECT_NAME    = var.project_name
      EVIDENCE_BUCKET = length(aws_s3_bucket.soar_evidence) > 0 ? aws_s3_bucket.soar_evidence[0].bucket : ""
      LOG_LEVEL       = "INFO"
    }
  }

  depends_on = [
    aws_iam_role_policy.soar_lambda_policy
  ]
}
