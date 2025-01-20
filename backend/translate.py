import sys
import re
import os
import logging
from PIL import Image
import cv2
import easyocr
import numpy as np
import requests
import json  
from dotenv import load_dotenv
load_dotenv()

os.environ['PYTHONIOENCODING'] = 'utf-8'

logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler("translation.log", encoding="utf-8"),
        logging.StreamHandler(stream=sys.stderr)
    ]
)
logger = logging.getLogger(__name__)

LANGUAGE_MAPPING = { "English": {"easyocr": "en", "helsinki": "en", "facebook": "en_XX"},
                    "French": {"easyocr": "fr", "helsinki": "fr", "facebook": "fr_XX"},
                    "Spanish": {"easyocr": "es", "helsinki": "es", "facebook": "es_XX"},
                    "Arabic": {"easyocr": "ar", "helsinki": "ar", "facebook": "ar_AR"},
                    "German": {"easyocr": "de", "helsinki": "de", "facebook": "de_DE"},
                    "Chinese": {"easyocr": "ch_sim", "helsinki": "zh", "facebook": "zh_CN"},
                    "Russian": {"easyocr": "ru", "helsinki": "ru", "facebook": "ru_RU"}, 
                    "Italian": {"easyocr": "it", "helsinki": "it", "facebook": "it_IT"}, 
                    "Portuguese": {"easyocr": "pt", "helsinki": "pt", "facebook": "pt_XX"}, 
                    "Japanese": {"easyocr": "ja", "helsinki": "ja", "facebook": "ja_XX"},}

#HUGGINGFACE_API_URL = "https://api-inference.huggingface.co/models/google-t5/t5-base"
HUGGINGFACE_API_URL = "https://api-inference.huggingface.co/models/facebook/mbart-large-50-many-to-many-mmt"

HUGGINGFACE_API_TOKEN =  os.getenv("Hugging_API_KEY")

def extract_text_from_image(image_path, language_code):
    """Extract text from an image using EasyOCR."""
    try:
        logger.info(f"Extracting text using EasyOCR with language: {language_code}")
        reader = easyocr.Reader([language_code])
        
        img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
        _, thresh = cv2.threshold(img, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        blur = cv2.GaussianBlur(thresh, (5, 5), 0)
        cv2.imwrite("processed_image.jpg", blur)  
        
        result = [text for text in reader.readtext(blur) if text[2] > 0.7]
        extracted_text = " ".join([text[1] for text in result])
        
        if not extracted_text.strip():
            logger.warning("No text detected in the image.")
        return extracted_text.strip()
    except Exception as e:
        logger.error(f"Error during OCR: {e}")
        raise

def clean_extracted_text(text):
    """Clean extracted text by removing unnecessary characters."""
    try:
        logger.info("Cleaning extracted text.")
        text = re.sub(r"[^\w\s.,?!äöüÄÖÜß-]", "", text)
        text = re.sub(r"\s+", " ", text).strip()
        return text
    except Exception as e:
        logger.error(f"Error during text cleaning: {e}")
        raise

def query(payload):
    """Query the Hugging Face API."""
    try:
        headers = {
            "Authorization": f"Bearer {HUGGINGFACE_API_TOKEN}",
            "Content-Type": "application/json"
        }
        data = json.dumps(payload)
        response = requests.post(HUGGINGFACE_API_URL, headers=headers, data=data)
        response.raise_for_status() 
        return json.loads(response.content.decode("utf-8"))
    except Exception as e:
        logger.error(f"Error during translation API request: {e}")
        raise

def translate_text(text, source_language, target_language):
    """Translate text using the Hugging Face API with full language names."""
    
    try:
        logger.info(f"Translating text from {source_language} to {target_language} using Hugging Face API.")
        normalized_text = " ".join(text.split()).strip()
        if source_language == "ar_AR":
            target_language = target_language[:-3]
            source_language = source_language[:-3]
            HUGGINGFACE_API_URL = "https://api-inference.huggingface.co/models"
            logger.info(f"Translating text from {source_language} to {target_language} using Hugging Face API.")
            model_name = f"Helsinki-NLP/opus-mt-{source_language}-{target_language}"
            headers = {"Authorization": f"Bearer {HUGGINGFACE_API_TOKEN}"}
            payload = {"inputs": text}
            response = requests.post(f"{HUGGINGFACE_API_URL}/{model_name}", headers=headers, json=payload)
            response.raise_for_status()
            result = response.json()
            translated_text = result[0]["translation_text"]
            return translated_text
        if target_language!="en_XX":
            payload = {
            "inputs": normalized_text.lower(),
            "parameters": {
                "src_lang": source_language,
                "tgt_lang": "en_XX"
            },
            }
            
            logger.debug(f"Payload being sent to API: {payload}")

            response = query(payload)
        
            logger.debug(f"API response: {response}")
            logger.info(f"translate {source_language} to {target_language}: {text.lower()}")
        
            if isinstance(response, list) and len(response) > 0:
                translated_text = response[0].get("translation_text", "")
                payload = {
            "inputs": translated_text.lower(),
            "parameters": {
                "src_lang": "en_XX",
                "tgt_lang": target_language
            },
        }
                response = query(payload)
                logger.debug(f"API response: {response}")
                translated_text = response[0].get("translation_text", "")
                if not translated_text:
                    logger.warning("Translation not found in response.")
                    logger.info(f"Translated text: {translated_text}")
                return translated_text
            else:
                logger.error("Invalid response format or empty response received.")
        else:
            payload = {
            "inputs": normalized_text.lower(),
            "parameters": {
                "src_lang": source_language,
                "tgt_lang": "en_XX"
            },
            } 
            logger.debug(f"Payload being sent to API: {payload}")
            response = query(payload)
        
            logger.debug(f"API response: {response}")
            logger.info(f"translate {source_language} to {target_language}: {text.lower()}")

            translated_text = response[0].get("translation_text", "")
            return translated_text   
        return None
    except Exception as e:
        logger.error(f"Translation error: {e}")
        raise

def main(image_path, source_language, target_language):
    """Main workflow for text extraction and translation."""
    try:
        if source_language.capitalize() not in LANGUAGE_MAPPING or target_language.capitalize() not in LANGUAGE_MAPPING:
            logger.error("Unsupported language provided.")
            return None
        source_lang_code = LANGUAGE_MAPPING[source_language.capitalize()]["easyocr"]
        source_helsinki_code = LANGUAGE_MAPPING[source_language.capitalize()]["facebook"]
        target_helsinki_code = LANGUAGE_MAPPING[target_language.capitalize()]["facebook"]
        
        extracted_text = extract_text_from_image(image_path, source_lang_code)
        logger.info(f"Extracted text: {extracted_text.encode('utf-8', 'ignore').decode('utf-8')}")
        if not extracted_text:
            return None
        
        cleaned_text = clean_extracted_text(extracted_text)
        logger.info(f"Cleaned text: {cleaned_text}")
        
        translated_text = translate_text(cleaned_text, source_helsinki_code, target_helsinki_code)
        logger.info(f"Translated text: {translated_text}")
        
        result = {
            "originalText": cleaned_text,
            "translatedText": translated_text
        }
        print(json.dumps(result)) 
        return result
    except Exception as e:
        logger.error(f"Error in main workflow: {e}")
        return None

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python translate.py <image_path> <source_language> <target_language>")
        sys.exit(1)

    image_path = sys.argv[1]
    source_language = sys.argv[2]
    target_language = sys.argv[3]
    result = main(image_path, source_language, target_language)
    if not result:
        sys.exit(1)
