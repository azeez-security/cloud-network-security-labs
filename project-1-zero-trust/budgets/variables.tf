variable "region" {
  type    = string
  default = "us-east-1"
}

variable "budget_name" {
  type    = string
  default = "finops-monthly-cost"
}

variable "monthly_budget_usd" {
  type    = number
  default = 200
}

variable "alert_email" {
  type    = string
  default = "azeezlawunmi@gmail.com"
}

# Alert thresholds as percentages
variable "thresholds" {
  type    = list(number)
  default = [25, 50, 80, 100]
}

# Optional: filter by linked account (single account use-case)
variable "linked_account_id" {
  type    = string
  default = null
}
