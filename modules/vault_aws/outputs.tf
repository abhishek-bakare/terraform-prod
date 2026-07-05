output "kms_key_id" {
    description = "This is vault KMS key id"
    value = aws_kms_key.vault.key_id
}