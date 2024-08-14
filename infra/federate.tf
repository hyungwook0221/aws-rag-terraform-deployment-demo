# Existing data source for TLS certificate
data "tls_certificate" "rag-demo" {
  url = aws_eks_cluster.demo.identity[0].oidc[0].issuer
}

# Existing IAM OpenID Connect provider
resource "aws_iam_openid_connect_provider" "rag-demo" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.rag-demo.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.rag-demo.url
}

# Existing IAM policy document for role assumption
data "aws_iam_policy_document" "rag-demo_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.rag-demo.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:chatbot:chatbot"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.rag-demo.arn]
      type        = "Federated"
    }
  }
}

# Existing IAM role
resource "aws_iam_role" "rag-demo" {
  assume_role_policy = data.aws_iam_policy_document.rag-demo_assume_role_policy.json
  name               = "rag-demo"
}

# New IAM policy document for Bedrock model invocation
data "aws_iam_policy_document" "bedrock_invoke_policy" {
  statement {
    actions = ["bedrock:InvokeModel"]
    effect  = "Allow"
    
    resources = [
      "arn:aws:bedrock:*::foundation-model/*"
    ]
  }
}

# New IAM policy resource for Bedrock model invocation
resource "aws_iam_policy" "bedrock_invoke_policy" {
  name   = "bedrock_invoke_policy"
  policy = data.aws_iam_policy_document.bedrock_invoke_policy.json
}

# Attach the Bedrock invocation policy to the existing IAM role
resource "aws_iam_role_policy_attachment" "rag_demo_attach_bedrock_policy" {
  role       = aws_iam_role.rag-demo.name
  policy_arn = aws_iam_policy.bedrock_invoke_policy.arn
}
