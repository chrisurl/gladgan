# link_processor.py
import requests
from bs4 import BeautifulSoup
import re
from urllib.parse import urljoin

def is_pdf_link(url):
    """Check if URL is a direct link to a PDF"""
    return url.lower().endswith('.pdf') or '/pdf/' in url.lower()

def extract_year(text):
    """Extract year from text if present"""
    year_match = re.search(r'20\d{2}', text)
    if year_match:
        return year_match.group(0)
    return None

def extract_pdf_links(url):
    """Extract PDF links from a webpage that might be annual reports"""
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        soup = BeautifulSoup(response.text, 'html.parser')
        pdf_links = []
        
        for link in soup.find_all('a', href=True):
            href = link.get('href', '')
            if not href:
                continue
                
            if not href.startswith(('http://', 'https://')):
                href = urljoin(url, href)
                
            if is_pdf_link(href):
                link_text = link.get_text().strip()
                
                # Keywords that might indicate an annual report
                keywords = ['annual report', 'annual-report', 'financial report', 'annual results']
                
                if any(keyword in link_text.lower() or keyword in href.lower() for keyword in keywords):
                    year = extract_year(href) or extract_year(link_text)
                    pdf_links.append({
                        'url': href,
                        'text': link_text,
                        'year': year
                    })
        
        return pdf_links
        
    except Exception as e:
        print(f"Error processing {url}: {e}")
        return []