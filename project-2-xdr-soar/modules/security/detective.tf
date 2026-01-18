########################################
# AWS Detective – Investigation Graph
########################################

resource "aws_detective_graph" "this" {
  count = var.enable_detective ? 1 : 0

  tags = {
    Project = var.project_name
    Layer   = "xdr-baseline"
  }
}

########################################
# Optional: Invite a separate AWS account
# (disabled by default for single-account labs)
########################################

resource "aws_detective_member" "member" {
  count = (
    var.enable_detective &&
    var.enable_detective_members &&
    var.detective_member_account_id != "" &&
    var.detective_member_email != ""
  ) ? 1 : 0

  graph_arn      = aws_detective_graph.this[0].graph_arn
  account_id     = var.detective_member_account_id
  email_address  = var.detective_member_email
  message        = "CloudBank XDR/SOAR Detective Membership"

  depends_on = [aws_detective_graph.this]
}

