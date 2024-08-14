resource "kubernetes_namespace" "chatbot" {
  depends_on = [ aws_eks_node_group.demo ]
  metadata {
    name = "chatbot"
  }
}

# Define the ServiceAccount
resource "kubernetes_service_account" "chatbot" {
  metadata {
    name      = "chatbot"
    namespace = kubernetes_namespace.chatbot.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.rag-demo.arn
    }
  }
}

# Define the ConfigMap for app code
resource "kubernetes_config_map" "app_code" {
  metadata {
    name      = "app-code"
    namespace = kubernetes_namespace.chatbot.metadata[0].name
  }

  data = {
    "app.py"           = file("../sample-application/chatbot.py")
    "requirements.txt" = file("../sample-application/requirements.txt")
  }
}

# Define the Pod
resource "kubernetes_pod" "chatbot" {
  metadata {
    name      = "chatbot"
    namespace = kubernetes_namespace.chatbot.metadata[0].name
    labels = {
      run = "chatbot"
    }
  }

  spec {
    service_account_name = kubernetes_service_account.chatbot.metadata[0].name

    container {
      name  = "chatbot"
      image = "ubuntu:20.04"

      env {
        name  = "VAULT_ADDR"
        value = var.vault_addr
      }
      env {
        name  = "VAULT_TOKEN"
        value = var.vault_token
      }
      env {
        name  = "VAULT_NAMESPACE"
        value = "admin"
      }
      env {
        name  = "AWS_REGION"
        value = var.region
      }
      env {
        name  = "BEDROCK_MODEL_ID"
        value = var.bedrock_model_id
      }
      env {
        name  = "BEDROCK_EMBEDDING_MODEL_ID"
        value = var.bedrock_embedding_model_id
      }

      command = [
        "sh", "-c", <<-EOF
          echo "Updating and installing packages..." && \
          apt-get update && \
          apt-get install -y python3 python3-pip && \
          echo "Creating directory structure..." && \
          mkdir -p /tmp/app/config && \
          pip install llama_index && \
          pip install langchain boto3 && \
          pip install langchain-aws && \
          pip install langchain_community && \
          pip install faiss-cpu && \
          echo "Installing requirements..." && \
          pip3 install -r /app/requirements.txt && \
          echo "Starting application..." && \
          streamlit run /app/app.py
        EOF
      ]
      
      port {
        container_port = 8501
        protocol       = "TCP"
      }

      volume_mount {
        name      = "app-code"
        mount_path = "/app"
      }
    }

    volume {
      name = "app-code"
      config_map {
        name = kubernetes_config_map.app_code.metadata[0].name
      }
    }
  }
}

# Define the Service
resource "kubernetes_service" "chatbot" {
  metadata {
    name      = "chatbot"
    namespace = kubernetes_namespace.chatbot.metadata[0].name
  }

  spec {
    selector = {
      run = "chatbot"
    }

    port {
      port        = 80
      target_port = 8501
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }
}
