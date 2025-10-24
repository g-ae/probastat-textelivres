from ebooklib import epub, ITEM_DOCUMENT
from bs4 import BeautifulSoup
import os

def epub_to_txt(epub_path, txt_path):
    # Read the EPUB file
    book = epub.read_epub(epub_path)

    # Collect all text from the EPUB
    text_content = []
    for item in book.get_items():
        if item.get_type() == ITEM_DOCUMENT:  # ✅ Fixed here
            soup = BeautifulSoup(item.get_body_content(), 'html.parser')
            text_content.append(soup.get_text())

    # Join and write to TXT file
    full_text = '\n'.join(text_content)
    with open(txt_path, 'w', encoding='utf-8') as f:
        f.write(full_text)

    print(f"✅ Successfully converted '{epub_path}' → '{txt_path}'")


if __name__ == "__main__":

    mouvement = "naturalisme"  
    epub_dir = "book_data/" + mouvement + "/romans_epub"
    txt_dir = "book_data/" + mouvement

    for file in os.listdir(epub_dir):
        if file.endswith(".epub"):
            epub_to_txt(os.path.join(epub_dir, file), os.path.join(txt_dir, file.replace(".epub", ".txt")))
