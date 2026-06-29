# --- Security group: only ECS tasks can reach the database ---
resource "aws_security_group" "rds" {
  name        = "capstone-rds-sg"
  description = "Allow PostgreSQL from ECS tasks only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "capstone-rds-sg" }
}

# --- Subnet group: tells RDS to live in the PRIVATE subnets ---
resource "aws_db_subnet_group" "main" {
  name       = "capstone-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  tags       = { Name = "capstone-db-subnet-group" }
}

# --- The PostgreSQL database ---
resource "aws_db_instance" "main" {
  identifier     = "capstone-db"
  engine         = "postgres"
  engine_version = "16.4"
  instance_class = "db.t3.micro" # free-tier eligible

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true # encryption at rest (security)

  db_name  = "urlshortener"
  username = "appuser"
  password = random_password.db.result # from Secrets Manager-stored random pw

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false # NEVER reachable from internet
  skip_final_snapshot = true  # no snapshot on destroy (lab convenience)
  deletion_protection = false # allow terraform destroy

  tags = { Name = "capstone-db" }
}
