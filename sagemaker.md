### Install Dependencies
pip install pymupdf nltk

import nltk
nltk.download("stopwords")
nltk.download("punkt")
nltk.download("punkt_tab")

### Fuction to extract the pdf and splitting.
import fitz
def extract_pdf(pdf_path):
    document_text = ""
    with fitz.open(pdf_path) as doc:
        for page_num in range(doc.page_count):
            page = doc[page_num]
            document_text += page.get_text() + "\n"
    #split text into four parts
    split_length = len(document_text) // 4
    part1 = document_text[:split_length]
    part2 = document_text[:split_length:split_length*2]
    part3 = document_text[:split_length*2:split_length*3]
    part4 = document_text[:split_length*3:]
    
    return {
        "part1": part1,
        "part2": part2,
        "part3": part3,
        "part4": part4
    }

### Defining path to theknowledge base
knowledge_base = {
    "S3": extract_pdf("aws-docs/s3.pdf"),
    "EC2": extract_pdf("aws-docs/ec2.pdf"),
    "IAM": extract_pdf("aws-docs/iam.pdf")
}

## Verify if the split is done properly
def verify_pdf_splits():
    for service, content_parts in knowledge_base.items():
        print (f"\n--- Verifying splits for service: {service} ---")
        for part, content in content_parts.items():
            print(f"{part} - Length: {len(content)} characters")
            print(content[:500])
            print ("\n" + "="*50 + "\n")

### quey matching
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize

stop_words = set(stopwords.words("english"))

def match_query_to_text(service_name, query):
    service_content = knowledge_base.get(service_name, {})
    query_tokens = [word for word in word_tokenize(query.lower()) if word.isalnum() and word not in stop_words]
    relevant_text = ""
    for part_name, content in service_content.items():
        sentences = content.split("\n")
        for sentence in sentences:
            sentence_tokens = [word for word in word_tokenize(sentence.lower()) if word.isalnum()]
            if all(word in sentence_tokens for word in query_tokens):
                relevant_text += sentence + "\n"
    return relevant_text if relevant_text else "I'm sorry, I couldn't find an answer in my knowledge base"

## defining chatbot behavior
def chatbot(service_name, user_question):
    if any(keyword in user_question.lower() for keyword in ["overview", "introduction", "basics"]):
        part = "part1"
    elif any(keyword in user_question.lower() for keyword in ["setup", "get started", "usage"]):
        part = "part2"
    elif any(keyword in user_question.lower() for keyword in ["features", "advanced", "details"]):
        part = "part3"
    elif any(keyword in user_question.lower() for keyword in ["pricing", "cost", "limitations"]):
        part = "part4"
    else:
        part = None
    
    if part:
        answer = match_query_to_text(service_name, user_question)
    else:
        answer = match_query_to_text(service_name, user_question)
    return answer

### Actual chat with Chatbot
def chat_with_chatbot():
    print ("Welcome to AWS services FAQ's Knowledge Base Chatbot! Type 'exit' to end the chat.")
    
    while True:
        service_name = input("Enter AWS Service (S3, EC2, IAM): ")
        if service_name.lower() == 'exit':
            print("Goodbye!")
            break
        elif service_name not in knowledge_base:
            print("Sorry, I only have information for S3, EC2 and IAM")
            continue
        user_question = input("question: ")
        response = chatbot(service_name, user_question)
        print("Bot:", response)
    
