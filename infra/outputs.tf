output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.demo.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = aws_eks_cluster.demo.vpc_config[0].security_group_ids
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = aws_eks_cluster.demo.name
}

output "connection_command" {
  description = "Command to connect to the EKS cluster"
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${aws_eks_cluster.demo.name} then kubectl get service -n chatbot to connect to the Chatbot App" 
}