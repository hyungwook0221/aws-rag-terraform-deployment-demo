variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "my-rag-app"
}

//vault address
variable "vault_addr" {
  type    = string
  default = "https://vault-public-vault-568210d2.b06d58cb.z1.hashicorp.cloud:8200"
}

//vault token
variable "vault_token" {
  type    = string
  default = "hvs.CAESINz7QQDXDY3xNOUUcGaYpB3OAr8Rw-2m8YyOoVWOlJbWGigKImh2cy40SjlRemkyOWJsdlhVYnhUaHJNdWdrV0guVWhUQTcQ4KA3"
}

//bedrock model
variable "bedrock_model_id" {
  type    = string
  default = "anthropic.claude-3-sonnet-20240229-v1:0"
}

//bedrock embedding model
variable "bedrock_embedding_model_id" {
  type    = string
  default = "amazon.titan-embed-text-v1"
}