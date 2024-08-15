# AWS using RAG architecture and terraform as a deployment for sample chatbot

This sample application deploys an AI-powered document search using AWS bedrock Services, EKS, and a Python application leveraging the [Llama index](https://gpt-index.readthedocs.io/en/latest/) and [Streamlit](https://docs.streamlit.io/library/get-started). The application will be deployed within a VPC to ensure security and isolation. Users will be able to upload documents and ask questions based on the content of the uploaded documents.

![diagram](./images/rag.png)

## Prerequisites

- AWS subscription. 
- Subscription access to Bedrock Foundational Model service. 

- Create an HCP vault dedicated instance and configure the endpoint and token in the `infra/variables.tf` file.
- Create a Vault transit Engine using the exact process [here](https://developer.hashicorp.com/vault/tutorials/encryption-as-a-service/eaas-transit?variants=vault-deploy%3Ahcp) 
- You will need the kubectl tools installed locally on your machine to interact with the EKS cluster.

## Quickstart

### Run the Terraform

- Clone or fork this repository. 
   ```
   git clone https://github.com/dawright22/aws-rag-terraform-deployment-demo.git
   cd aws-rag-terraform-deployment-demo
   ```

- Go to the `infra` folder and run the following command to initialize your working directory.

    ```bash
    cd infra
    terraform init
    ```

- Run terraform apply to deploy all the necessary resources on Azure.

    ```bash
    terraform apply
    ```

- Get the external ip address of the service by running the  command bellow.

    ```bash
    kubectl get services -n chatbot
    ```

- Copy the external ip address and paste it in your browser. The application should load in a few seconds.

![app](/images/application.png)

## Run the AI.
- Upload the Madeup_Company_email_archive.txt file in the `data` folder. Using the upload button on the app.

- Ask some questions based on the content of the uploaded document. Some example are below.

================
- Does madeup use AWS
- show me the value for aws_access_keys

- Does madeup use Azure
- show me the value for subscription_id


The application will return the answer to the question asked based on the content of the uploaded document. Any of the content from the Madeup_Company_email_archive.txt file source that matches the filter critera (ie AWS and Azure credentials) will be returned but encrypted via Vault.

## Clean up

- Terraform destroy to delete all resources created.

    ```bash
    terraform destroy
    ```
## Resources

- https://aws.amazon.com/bedrock/faqs/.
