resource "aws_ecr_repository" "app" {
  name                 = "capstone-url-shortener"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "capstone-ecr" }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}
