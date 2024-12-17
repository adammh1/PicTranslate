import sys
import re
import os
import logging
from PIL import Image
import cv2
import easyocr
import numpy as np
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler("translation.log", encoding="utf-8"),
        logging.StreamHandler(stream=sys.stderr)  
    ]
)
logger = logging.getLogger(__name__)

LANGUAGE_MAPPING = {
    "English": {"easyocr": "en", "helsinki": "en"},
    "French": {"easyocr": "fr", "helsinki": "fr"},
    "Spanish": {"easyocr": "es", "helsinki": "es"},
    "Arabic": {"easyocr": "ar", "helsinki": "ar"},
    "German": {"easyocr": "de", "helsinki": "de"},
    "Chinese": {"easyocr": "ch_sim", "helsinki": "zh"},
    "Russian": {"easyocr": "ru", "helsinki": "ru"},
    "Italian": {"easyocr": "it", "helsinki": "it"},
    "Portuguese": {"easyocr": "pt", "helsinki": "pt"},
    "Japanese": {"easyocr": "ja", "helsinki": "ja"}
}

CACHE_DIR = os.path.join(os.getcwd(), "huggingface_cache")
os.makedirs(CACHE_DIR, exist_ok=True)

def extract_text_from_image(image_path, language_code):
    try:
        logger.info(f"Extracting text using EasyOCR with language: {language_code}")
        reader = easyocr.Reader([language_code])
        img = cv2.imread(image_path, 0)
        blur = cv2.GaussianBlur(img, (5, 5), 0)
        img_np = np.array(blur)
        result = reader.readtext(img_np)
        extracted_text = " ".join([text[1] for text in result])
        if not extracted_text.strip():
            logger.warning("No text detected in the image.")
        return extracted_text.strip()
    except Exception as e:
        logger.error(f"Error during OCR: {e}")
        raise

def clean_extracted_text(text):
    try:
        logger.info("Cleaning extracted text.")
        text = re.sub(r"[^\w\s.,?!-]", "", text)
        text = re.sub(r"\s+", " ", text).strip()
        return text
    except Exception as e:
        logger.error(f"Error during text cleaning: {e}")
        raise

def translate_text(text, source_language_code, target_language_code):
    try:
        logger.info(f"Translating text from {source_language_code} to {target_language_code}.")
        model_name = f"Helsinki-NLP/opus-mt-{source_language_code}-{target_language_code}"
        tokenizer = AutoTokenizer.from_pretrained(model_name, cache_dir=CACHE_DIR)
        model = AutoModelForSeq2SeqLM.from_pretrained(model_name, cache_dir=CACHE_DIR)
        inputs = tokenizer.encode(text, return_tensors="pt", truncation=True)
        outputs = model.generate(inputs, max_length=512, num_beams=5)
        translated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
        return translated_text
    except Exception as e:
        logger.error(f"Translation error: {e}")
        raise

def main(image_path, source_language, target_language):
    try:
        if source_language.capitalize() not in LANGUAGE_MAPPING or target_language.capitalize() not in LANGUAGE_MAPPING:
            logger.error("Unsupported language provided.")
            return None
        source_lang_code = LANGUAGE_MAPPING[source_language.capitalize()]["easyocr"]
        source_helsinki_code = LANGUAGE_MAPPING[source_language.capitalize()]["helsinki"]
        target_helsinki_code = LANGUAGE_MAPPING[target_language.capitalize()]["helsinki"]
        extracted_text = extract_text_from_image(image_path, source_lang_code)
        if not extracted_text:
            return None
        cleaned_text = clean_extracted_text(extracted_text)
        translated_text = translate_text(cleaned_text, source_helsinki_code, target_helsinki_code)
        return translated_text
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
    if result:
        print(result)  
    else:
        sys.exit(1)
