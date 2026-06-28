# Generate a random DB password (never typed by a human)
resource "random_password" "db" {
  length  = 24
  special = true
  # exclude chars that can break connection strings
  override_special = "!#$%*()-_=+[]{}"
}

# Store it in Secrets Manager
resource "aws_secretsmanager_secret" "db" {
  name        = "capstone/db-password"
  description = "RDS password for the URL shortener"
  # allows recreating a secret with the same name shortly after destroy
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = random_password.db.result
}
