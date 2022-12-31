output "id" {
  value       = aws_acm_certificate.certificate.id
  description = "The ID of the Certificate."
}

output "arn" {
  value       = aws_acm_certificate.certificate.arn
  description = "The ARN of the Certificate."
}
