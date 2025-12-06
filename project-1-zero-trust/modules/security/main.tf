# Application security group (only HTTP/S from load balancer – to be wired later)
resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "App tier security group"
  vpc_id      = var.vpc_id

  # Example: allow HTTP from anywhere (we'll tighten later)
  ingress {
    description = "App HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "app-sg" })
}

# Database SG: allow from app SG only (Zero Trust style)
resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "DB tier security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "DB from app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "db-sg" })
}
