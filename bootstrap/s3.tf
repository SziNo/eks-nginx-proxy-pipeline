# S3 bucket a fő Terraform remote state-jének. A zárolás a use_lockfile miatt egy .tflock
# fájllal történik ugyanebben a bucketben, ezért DynamoDB tábla nem kell.
resource "aws_s3_bucket" "state" {
  bucket = local.state_bucket_name

  # Védőháló: a state elvesztése után a Terraform nem tudná, mit kezel. A bucketet csak
  # ennek a sornak a kivétele után lehet törölni (lásd README, lebontás).
  lifecycle {
    prevent_destroy = true
  }
}

# Versioning: egy elrontott vagy felülírt state korábbi változata visszaállítható.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Alapértelmezett titkosítás (SSE-S3). A state érzékeny adatokat is tartalmazhat.
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Nyilvános hozzáférés tiltása mind a négy kapcsolóval (ACL és bucket policy oldalon is).
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
