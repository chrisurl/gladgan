import requests
from bs4 import BeautifulSoup
import re
import time
import random
import pandas as pd
import os
import urllib.parse
from datetime import datetime
import csv
from urllib.parse import urljoin, urlparse
import urllib.request

class FinancialStatementFinder:
    def __init__(self, download_folder="downloaded_reports"):
        self.headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
            "Accept-Language": "en-US,en;q=0.9",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        }
        
        # Create download folder if it doesn't exist
        self.download_folder = download_folder
        os.makedirs(self.download_folder, exist_ok=True)
        
        # Current year
        self.current_year = datetime.now().year
    
    def search_annual_report(self, company_name):
        """
        Search for the company's annual report using DuckDuckGo
        """
        # Format the search query
        search_query = f"{company_name} annual report {self.current_year}"
        print(f"  Searching for: {search_query}")
        
        try:
            # Encode the query for URL
            encoded_query = urllib.parse.quote_plus(search_query)
            search_url = f"https://duckduckgo.com/html/?q={encoded_query}"
            
            response = requests.get(search_url, headers=self.headers, timeout=15)
            if response.status_code != 200:
                print(f"  Search failed with status code: {response.status_code}")
                return []
                
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Extract search results
            results = []
            
            # DuckDuckGo search results are in elements with class 'result'
            result_elements = soup.select('.result')
            
            for result in result_elements[:5]:  # Check top 5 results
                # Get the link element
                link_element = result.select_one('.result__a')
                if not link_element:
                    continue
                    
                # Extract the title and URL
                title = link_element.text.strip()
                href = link_element.get('href')
                
                # DuckDuckGo uses a redirect URL, extract the actual URL
                parsed_url = urllib.parse.parse_qs(urllib.parse.urlparse(href).query)
                if 'uddg' in parsed_url:
                    actual_url = parsed_url['uddg'][0]
                else:
                    # If we can't extract the URL from the redirect, use the href directly
                    actual_url = href
                
                # Check if URL contains terms related to investor relations or annual reports
                relevant_terms = ['annual', 'report', 'investor', 'financial', 'statements', 
                                 'annual-report', 'jahresbericht', 'geschaeftsbericht']
                
                url_lower = actual_url.lower()
                title_lower = title.lower()
                
                if any(term in url_lower or term in title_lower for term in relevant_terms):
                    results.append({
                        'title': title,
                        'url': actual_url
                    })
            
            return results
            
        except Exception as e:
            print(f"  Error in search: {e}")
            return []
    
    def find_and_download_report(self, url, company_name):
        """
        Find download links and download the PDF report
        """
        try:
            print(f"  Checking page: {url}")
            
            response = requests.get(url, headers=self.headers, timeout=15)
            if response.status_code != 200:
                print(f"  Failed to load page: {response.status_code}")
                return None, None
                
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Look for download buttons/links
            download_candidates = []
            
            # 1. Look for buttons or links with "download" text or class
            download_elements = soup.find_all(['a', 'button'], text=re.compile(r'download|herunterladen|télécharger|download\s+pdf', re.I))
            download_elements += soup.find_all(['a', 'button'], class_=re.compile(r'download|btn-download', re.I))
            
            # 2. Look for links containing common annual report terms
            report_elements = soup.find_all('a', text=re.compile(r'annual\s+report|annual\s+financial|jahresbericht|geschäftsbericht|complete\s+report|full\s+report', re.I))
            
            # Combine and process all candidates
            for element in download_elements + report_elements:
                # For buttons, look for nested <a> tags
                if element.name == 'button':
                    link = element.find('a')
                    if link:
                        href = link.get('href')
                    else:
                        # Button might use JavaScript to trigger download
                        # Check for data attributes that might contain the URL
                        for attr in ['data-url', 'data-href', 'data-download']:
                            if element.has_attr(attr):
                                href = element.get(attr)
                                break
                        else:
                            continue  # Skip if no URL found
                else:
                    href = element.get('href')
                
                if not href:
                    continue
                
                # Make absolute URL if relative
                if not href.startswith(('http://', 'https://')):
                    href = urljoin(url, href)
                
                # Check if this is likely a PDF link
                is_pdf = href.lower().endswith('.pdf') or 'pdf' in href.lower()
                text = element.get_text().strip()
                
                # Extract year from text or URL
                year_match = re.search(r'20\d{2}', href) or re.search(r'20\d{2}', text)
                year = year_match.group(0) if year_match else str(self.current_year)
                
                # Score this candidate
                score = 0
                if is_pdf:
                    score += 3
                if 'download' in text.lower() or 'download' in element.get('class', []):
                    score += 2
                if any(term in text.lower() for term in ['annual report', 'full report', 'complete report', 'jahresbericht']):
                    score += 3
                if year == str(self.current_year) or year == str(self.current_year - 1):
                    score += 2
                
                download_candidates.append({
                    'url': href,
                    'text': text,
                    'is_pdf': is_pdf,
                    'year': year,
                    'score': score
                })
            
            # If no direct download links found, look for PDF links
            if not download_candidates:
                pdf_links = soup.find_all('a', href=re.compile(r'\.pdf', re.I))
                
                for link in pdf_links:
                    href = link.get('href')
                    if not href:
                        continue
                        
                    # Make absolute URL if relative
                    if not href.startswith(('http://', 'https://')):
                        href = urljoin(url, href)
                        
                    text = link.get_text().strip()
                    
                    # Extract year from text or URL
                    year_match = re.search(r'20\d{2}', href) or re.search(r'20\d{2}', text)
                    year = year_match.group(0) if year_match else str(self.current_year)
                    
                    # Score this candidate
                    score = 0
                    score += 3  # It's a PDF
                    if any(term in text.lower() for term in ['annual', 'report', 'financial', 'statements']):
                        score += 2
                    if year == str(self.current_year) or year == str(self.current_year - 1):
                        score += 2
                    
                    download_candidates.append({
                        'url': href,
                        'text': text,
                        'is_pdf': True,
                        'year': year,
                        'score': score
                    })
            
            # Sort candidates by score and download the best one
            if download_candidates:
                download_candidates.sort(key=lambda x: x['score'], reverse=True)
                best_candidate = download_candidates[0]
                
                if best_candidate['score'] >= 3:  # Minimum threshold
                    # Try to download the PDF
                    print(f"  Found potential report: {best_candidate['url']}")
                    print(f"  Year: {best_candidate['year']}")
                    
                    # Create a filename for the PDF
                    safe_company_name = re.sub(r'[^\w\-\.]', '_', company_name)
                    filename = f"{safe_company_name}_annual_report_{best_candidate['year']}.pdf"
                    filepath = os.path.join(self.download_folder, filename)
                    
                    try:
                        # Download the file
                        print(f"  Downloading to: {filepath}")
                        
                        # Use a different User-Agent for file download
                        download_headers = {
                            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
                            "Accept": "application/pdf,*/*",
                            "Referer": url  # Add referer to appear legitimate
                        }
                        
                        req = urllib.request.Request(best_candidate['url'], headers=download_headers)
                        with urllib.request.urlopen(req) as response, open(filepath, 'wb') as out_file:
                            out_file.write(response.read())
                        
                        return filepath, best_candidate['year']
                        
                    except Exception as e:
                        print(f"  Error downloading file: {e}")
                        # Return the URL even if download failed
                        return best_candidate['url'], best_candidate['year']
            
            # If we couldn't find a direct PDF link, check if this is an investor relations page
            # that might have links to annual reports
            if "investor" in url.lower() and not download_candidates:
                # Look for links to potential annual report pages
                ar_pages = soup.find_all('a', text=re.compile(r'annual\s+report|financial\s+report', re.I))
                
                for page_link in ar_pages[:3]:  # Check top 3 potential pages
                    href = page_link.get('href')
                    if not href:
                        continue
                        
                    # Make absolute URL if relative
                    if not href.startswith(('http://', 'https://')):
                        href = urljoin(url, href)
                        
                    # Recursively check this page (with a depth limit of 1)
                    if href != url:  # Avoid infinite recursion
                        return self.find_and_download_report(href, company_name)
            
            return None, None
            
        except Exception as e:
            print(f"  Error processing page {url}: {e}")
            return None, None
    
    def process_company(self, company_name):
        """
        Process a single company to find and download its annual report
        """
        print(f"Processing: {company_name}")
        
        # First try with the current year
        search_results = self.search_annual_report(company_name)
        
        if not search_results:
            # If no results, try with previous year
            previous_year = self.current_year - 1
            search_query = f"{company_name} annual report {previous_year}"
            print(f"  No results found. Trying: {search_query}")
            
            # Temporarily modify current_year for the search
            original_year = self.current_year
            self.current_year = previous_year
            search_results = self.search_annual_report(company_name)
            self.current_year = original_year  # Restore original value
        
        if not search_results:
            print(f"  No search results found for {company_name}")
            return None, None
        
        # Try each search result
        for result in search_results:
            report_path, year = self.find_and_download_report(result['url'], company_name)
            
            if report_path:
                return report_path, year
            
            # Add delay between checking pages
            time.sleep(random.uniform(1, 2))
        
        print(f"  Could not find annual report for {company_name}")
        return None, None
    
    def process_company_list(self, company_list, output_file='financial_statements_results.csv'):
        """
        Process a list of companies and save results to CSV
        """
        results = []
        
        # Convert to list if DataFrame
        if isinstance(company_list, pd.DataFrame):
            if 'name' in company_list.columns:
                companies = company_list['name'].tolist()
            else:
                companies = company_list.iloc[:, 0].tolist()  # Assume first column has names
        else:
            companies = company_list
            
        total = len(companies)
        
        for i, company in enumerate(companies):
            print(f"Processing {i+1}/{total}: {company}")
            
            # Add random delay between companies to avoid being blocked
            if i > 0:
                time.sleep(random.uniform(2, 5))
                
            report_path, year = self.process_company(company)
            
            results.append({
                'company_name': company,
                'report_path': report_path,
                'year': year,
                'timestamp': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            })
            
            # Save intermediate results after each company
            with open(output_file, 'w', newline='', encoding='utf-8') as f:
                writer = csv.DictWriter(f, fieldnames=['company_name', 'report_path', 'year', 'timestamp'])
                writer.writeheader()
                writer.writerows(results)
                
        return pd.DataFrame(results)

# Function to handle batch processing with pauses
def process_in_batches(companies, batch_size=25, pause_minutes=15):
    """
    Process companies in batches with pauses to avoid IP blocks
    """
    finder = FinancialStatementFinder()
    all_results = []
    
    # Process in batches
    for i in range(0, len(companies), batch_size):
        batch = companies[i:i+batch_size]
        print(f"\nProcessing batch {i//batch_size + 1} of {(len(companies)-1)//batch_size + 1}")
        
        # Process this batch
        batch_results = finder.process_company_list(batch, f'financial_statements_batch_{i//batch_size + 1}.csv')
        all_results.append(batch_results)
        
        # Pause between batches (except for the last one)
        if i + batch_size < len(companies):
            pause_seconds = pause_minutes * 60
            print(f"\nPausing for {pause_minutes} minutes before next batch...")
            
            # Show a countdown
            for remaining in range(pause_seconds, 0, -60):
                print(f"  {remaining//60} minutes remaining...")
                time.sleep(60)
    
    # Combine all results
    combined_results = pd.concat(all_results, ignore_index=True)
    combined_results.to_csv('financial_statements_all_results.csv', index=False)
    
    return combined_results

# Example usage
def main():
    # Example list of companies
    companies = [
        "Siemens AG",
        "TotalEnergies SE",
        "Santander",
        "ING Group",
        "Eni SpA"
    ]
    
    # For small lists, process directly
    if len(companies) <= 25:
        finder = FinancialStatementFinder()
        results_df = finder.process_company_list(companies)
    else:
        # For larger lists, process in batches
        results_df = process_in_batches(companies)
    
    print("\nResults summary:")
    print(results_df)
    
    # Count successful finds
    success_count = results_df['report_path'].notna().sum()
    print(f"\nSuccessfully found {success_count} out of {len(companies)} annual reports")

if __name__ == "__main__":
    main()