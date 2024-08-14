import os
import sys
import re
import base64
import logging
import hvac
import streamlit as st
import boto3
from botocore.credentials import AssumeRoleWithWebIdentityCredentialFetcher, DeferredRefreshableCredentials
from botocore.session import get_session
from dotenv import load_dotenv, dotenv_values
from langchain_aws import ChatBedrock, BedrockEmbeddings
from langchain.vectorstores import FAISS
from langchain.chains import RetrievalQA
from langchain.document_loaders import TextLoader

# Load environment variables from .env file
load_dotenv()

# Configure logging
logging.basicConfig(stream=sys.stdout, level=logging.INFO)

# Print a list of all environment variables
logging.info("Environment variables loaded:")
for key, value in os.environ.items():
    logging.info(f"{key}: {value}")

# HashiCorp Vault configuration
vault_url = os.getenv('VAULT_ADDR')
vault_token = os.getenv('VAULT_TOKEN')
vault_namespace = os.getenv('VAULT_NAMESPACE')

client = hvac.Client(url=vault_url, token=vault_token, namespace=vault_namespace)

# Ensure the client is authenticated
if not client.is_authenticated():
    raise Exception("Vault authentication failed")

# Set up AWS credentials using Web Identity Token
role_arn = os.getenv('AWS_ROLE_ARN')
token_file = os.getenv('AWS_WEB_IDENTITY_TOKEN_FILE')

# Create session and credentials
session = boto3.Session()
sts_client = session.client('sts')

# Use STS to assume the role with web identity
assumed_role_object = sts_client.assume_role_with_web_identity(
    RoleArn=role_arn,
    WebIdentityToken=open(token_file).read(),
    RoleSessionName="chatbot-session"
)

credentials = assumed_role_object['Credentials']

# Set environment variables for the assumed role
os.environ['AWS_ACCESS_KEY_ID'] = credentials['AccessKeyId']
os.environ['AWS_SECRET_ACCESS_KEY'] = credentials['SecretAccessKey']
os.environ['AWS_SESSION_TOKEN'] = credentials['SessionToken']
os.environ['AWS_DEFAULT_REGION'] = os.getenv('AWS_REGION', 'us-east-1')

# Set up AWS Bedrock using LangChain
BEDROCK_MODEL_ID = os.getenv('BEDROCK_MODEL_ID', 'anthropic.claude-3-sonnet-20240229-v1:0')
bedrock_llm = ChatBedrock(
    model_id=BEDROCK_MODEL_ID,
    model_kwargs=dict(temperature=0)
)

# Set up AWS Bedrock Embeddings
bedrock_embedding_model_id = os.getenv('BEDROCK_EMBEDDING_MODEL_ID', 'amazon.titan-embed-text-v1')
bedrock_embeddings = BedrockEmbeddings(model_id=bedrock_embedding_model_id)

# Define regex patterns
regex_patterns = [
    r'AKIA[0-9A-Z]{16}',
    r'ASIA[0-9A-Z]{16}',
    r'[A-Za-z0-9/+=]{40}',
    r'(?<=")[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}(?=")'
]

if "config" not in st.session_state:
    # Read the environment variables
    config = dotenv_values(".env")
    st.session_state.config = config

if "response" not in st.session_state:
    st.session_state.response = ""

# Save current file name to avoid reprocessing document
if "current_file" not in st.session_state:
    st.session_state.current_file = None

# Function to replace sensitive information with encrypted values
def replace_matches_with_encryption(content):
    replacements = {}
    for pattern in regex_patterns:
        matches = re.findall(pattern, content)
        for match in matches:
            if match not in replacements:
                encrypted_value = encrypt_with_vault(match)
                replacements[match] = encrypted_value
            content = content.replace(match, replacements[match])
    return content, replacements

# Function to encrypt data using Vault
def encrypt_with_vault(plain_text):
    plain_text_base64 = base64.b64encode(plain_text.encode('utf-8')).decode('utf-8')
    encryption_response = client.secrets.transit.encrypt_data(
        name='orders',
        plaintext=plain_text_base64
    )
    return encryption_response['data']['ciphertext']

# Function to handle the "Send" button click
def send_click():
    if st.session_state.vector_store:
        retriever = st.session_state.vector_store.as_retriever()
        qa_chain = RetrievalQA.from_chain_type(
            llm=bedrock_llm,
            retriever=retriever
        )
        st.session_state.response = qa_chain.run(st.session_state.prompt)

st.title("AWS Bedrock Doc Chatbot")

sidebar_placeholder = st.sidebar.container()

uploaded_file = st.file_uploader("Choose a file")

if uploaded_file and uploaded_file.name != st.session_state.current_file:
    with st.spinner('Ingesting the file...'):
        try:
            bytes_data = uploaded_file.read()
            content = bytes_data.decode('utf-8')
            updated_content, _ = replace_matches_with_encryption(content)
            
            # Save the uploaded file to a temporary directory
            tmp_file_path = f"/tmp/{uploaded_file.name}"
            with open(tmp_file_path, "w") as f:
                f.write(updated_content)

            # Load document and create embeddings
            loader = TextLoader(file_path=tmp_file_path)
            documents = loader.load()
            
            # Create vector store
            st.session_state.vector_store = FAISS.from_documents(
                documents, bedrock_embeddings
            )

            st.session_state.current_file = uploaded_file.name
            st.session_state.file_content = updated_content  # Store content in session state for sidebar display
            st.session_state.response = ""  # Clean up the response when new file is uploaded
            st.success('Done!')
        except Exception as e:
            st.error(f"An error occurred: {e}")

# Display file contents in the sidebar
if "file_content" in st.session_state:
    with sidebar_placeholder:
        st.subheader("File Contents")
        st.text_area("Contents", st.session_state.file_content, height=400)

if st.session_state.current_file:
    st.text_input("Ask something: ", key="prompt", on_change=send_click)
    st.button("Send", on_click=send_click)
    if st.session_state.response:
        st.subheader("Response: ")
        st.success(st.session_state.response, icon="🤖")
