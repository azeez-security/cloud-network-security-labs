resource "aws_cloudwatch_event_rule" "securityhub_findings" {
  count       = var.enable_soar ? 1 : 0
  name        = "${var.project_name}-securityhub-findings"
  description = "Route Security Hub findings to SOAR dispatcher."

  event_pattern = jsonencode({
    "source": ["aws.securityhub"],
    "detail-type": ["Security Hub Findings - Imported"],
    "detail": {
      "findings": {
        "Severity": {
          "Label": ["CRITICAL", "HIGH", "MEDIUM"]
        }
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "securityhub_to_lambda" {
  count = var.enable_soar ? 1 : 0
  rule  = aws_cloudwatch_event_rule.securityhub_findings[0].name
  arn   = aws_lambda_function.soar_dispatcher[0].arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  count         = var.enable_soar ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.soar_dispatcher[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.securityhub_findings[0].arn
}
