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
  default = "Your HCP endpoint here"
}

//vault token
variable "vault_token" {
  type    = string
  default = "your token here"
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
