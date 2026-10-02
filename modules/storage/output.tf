output "bucket_id" {
  value = aws_s3_bucket.bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.bucket.arn
}

output "bucket_name" {
  value = aws_s3_bucket.bucket.bucket
}

output "bucket_domain_name" {
  description = "Regional domain name, useful for constructing URLs"
  value       = aws_s3_bucket.bucket.bucket_regional_domain_name
}