import requests
from bs4 import BeautifulSoup
import re
import pandas as pd
import urllib.parse
import time
import random
import csv
from urllib.parse import urljoin, urlparse
from datetime import datetime
import os

class FinancialReportFinder:
    def __init__(self):
        self.headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
            "Accept-Language": "en-US,en;q=0.9",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        }
        # Create results folder
        self.results_folder = "results"
        os.makedirs(self.results_folder, exist_ok=True)
        
        # Set longer timeout for requests (in seconds)
        self.request_timeout = 30
        
        # Define non-European domains to avoid
        self.non_european_domains = ['.gov', '.us', '.ca', '.au', '.nz', '.jp', '.cn', '.kr', '.in', '.br']
    
    def search_duckduckgo(self, query):
        """Search DuckDuckGo and return results"""
        try:
            encoded_query = urllib.parse.quote_plus(query)
            search_url = f"https://www.duckduckgo.com/html/?q={encoded_query}"
            
            response = requests.get(search_url, headers=self.headers, timeout=self.request_timeout)
            
            # Handle 202 status code (request accepted but processing)
            if response.status_code == 202:
                print(f"Request accepted, waiting for processing (status code 202)")
                # Wait and retry up to 3 times
                for attempt in range(3):
                    print(f"Waiting 5 seconds before retry (attempt {attempt+1}/3)...")
                    time.sleep(5)
                    response = requests.get(search_url, headers=self.headers, timeout=self.request_timeout)
                    if response.status_code == 200:
                        print("Request processed successfully")
                        break
                    print(f"Still processing (status code {response.status_code})")
            
            if response.status_code != 200:
                print(f"Search failed with status code: {response.status_code}")
                return []
                
            soup = BeautifulSoup(response.text, 'html.parser')
            results = []
            
            # Extract search results
            for result in soup.select('.result'):
                link_element = result.select_one('.result__a')
                if not link_element:
                    continue
                    
                title = link_element.text.strip()
                href = link_element.get('href')
                
                # Extract actual URL from DuckDuckGo redirect
                parsed_url = urllib.parse.parse_qs(urllib.parse.urlparse(href).query)
                if 'uddg' in parsed_url:
                    actual_url = parsed_url['uddg'][0]
                else:
                    actual_url = href
                
                # Skip non-European domains (like .gov)
                if any(domain in actual_url.lower() for domain in self.non_european_domains):
                    print(f"Skipping non-European domain: {actual_url}")
                    continue
                
                results.append({
                    'title': title,
                    'url': actual_url
                })
            
            return results
            
        except Exception as e:
            print(f"Error in search: {e}")
            return []
    
    def normalize_company_name(self, company_name):
        """Normalize company name for better searching"""
        # Remove common suffixes
        suffixes = [' PLC', ' AG', ' NV', ' AB', ' GROUP', ' S P A', ' INC', ' LTD', ' GROUP PLC']
        name = company_name
        for suffix in suffixes:
            name = name.replace(suffix, '')
        
        # Remove non-alphanumeric characters
        name = re.sub(r'[^a-zA-Z0-9\s]', '', name)
        
        # Convert to lowercase and strip
        name = name.lower().strip()
        
        return name
    
    def find_investor_relations_page(self, query):
        """Find the investor relations or annual report page for a company"""
        # Create EU-focused search queries
        search_queries = [query]
        if 'europe' not in query.lower() and 'eu' not in query.lower():
            # Add European focus if not already present
            search_queries.append(query + " European Union")
        
        all_results = []
        for search_query in search_queries:
            print(f"Searching for: {search_query}")
            results = self.search_duckduckgo(search_query)
            
            # Filter out non-European domains
            filtered_results = []
            for result in results:
                url_lower = result['url'].lower()
                if not any(domain in url_lower for domain in self.non_european_domains):
                    filtered_results.append(result)
                else:
                    print(f"Filtered out non-European result: {result['url']}")
            
            all_results.extend(filtered_results)
            
            # If we found good results, no need to try more queries
            if len(filtered_results) >= 3:
                break
                
            time.sleep(random.uniform(2, 3))  # Avoid rate limiting
        
        # Filter for likely investor relations pages
        ir_pages = []
        for result in all_results:
            url_lower = result['url'].lower()
            title_lower = result['title'].lower()
            
            # Keywords that indicate it might be an investor relations page
            keywords = [
                'investor', 'annual report', 'financial report', 
                'investor relations', 'annual-report', 'financial', 
                'shareholders', 'annual results', 'reports'
            ]
            
            if any(keyword in url_lower or keyword in title_lower for keyword in keywords):
                ir_pages.append(result)
        
        return ir_pages
    
    def extract_pdf_links(self, url):
        """Extract PDF links from a page"""
        try:
            print(f"Checking page: {url}")
            response = requests.get(url, headers=self.headers, timeout=self.request_timeout)
            
            # Handle 202 status code (request accepted but processing)
            if response.status_code == 202:
                print(f"Request accepted, waiting for processing (status code 202)")
                # Wait and retry up to 3 times
                for attempt in range(3):
                    print(f"Waiting 5 seconds before retry (attempt {attempt+1}/3)...")
                    time.sleep(5)
                    response = requests.get(url, headers=self.headers, timeout=self.request_timeout)
                    if response.status_code == 200:
                        print("Request processed successfully")
                        break
                    print(f"Still processing (status code {response.status_code})")
            
            if response.status_code != 200:
                print(f"Failed to load page: {response.status_code}")
                return []
                
            soup = BeautifulSoup(response.text, 'html.parser')
            pdf_links = []
            
            # Look for direct PDF links
            for link in soup.find_all('a', href=True):
                href = link.get('href', '')
                if not href:
                    continue
                
                # Make absolute URL if relative
                if not href.startswith(('http://', 'https://')):
                    href = urljoin(url, href)
                
                # Check if it's a PDF link
                is_pdf = href.lower().endswith('.pdf') or '/pdf/' in href.lower()
                link_text = link.get_text().strip().lower()
                
                # Look for annual report keywords in the link text or URL
                report_keywords = [
                    'annual report', 'annual-report', 'financial report', 
                    'financial-report', 'annual financial', 'jahresbericht',
                    'yearly report', 'yearly-report', 'annual results'
                ]
                
                if is_pdf and any(keyword in link_text or keyword in href.lower() for keyword in report_keywords):
                    # Try to extract the year from the link text or URL
                    year_match = re.search(r'20\d{2}', href) or re.search(r'20\d{2}', link_text)
                    year = year_match.group(0) if year_match else "Unknown"
                    
                    # Score the link based on relevance
                    score = 0
                    if 'annual' in link_text or 'annual' in href.lower():
                        score += 3
                    if 'financial' in link_text or 'financial' in href.lower():
                        score += 2
                    if year.isdigit() and int(year) >= 2022:  # Prefer recent reports
                        score += 5
                    elif year.isdigit() and int(year) >= 2020:
                        score += 3
                    
                    pdf_links.append({
                        'url': href,
                        'text': link.get_text().strip(),
                        'year': year,
                        'score': score
                    })
            
            # If no direct PDF links found, look for download buttons or links
            if not pdf_links:
                download_buttons = soup.find_all(['a', 'button'], 
                    string=re.compile(r'download|herunterladen|télécharger', re.I))
                download_buttons += soup.find_all(['a', 'button'], 
                    class_=re.compile(r'download|btn-download', re.I))
                
                for button in download_buttons:
                    # For buttons, look for nested <a> tags
                    if button.name == 'button':
                        link = button.find('a')
                        if link:
                            href = link.get('href')
                        else:
                            # Button might use JavaScript to trigger download
                            for attr in ['data-url', 'data-href', 'data-download']:
                                if button.has_attr(attr):
                                    href = button.get(attr)
                                    break
                            else:
                                continue  # Skip if no URL found
                    else:
                        href = button.get('href')
                    
                    if not href:
                        continue
                    
                    # Make absolute URL if relative
                    if not href.startswith(('http://', 'https://')):
                        href = urljoin(url, href)
                    
                    # Check if it's likely a PDF link
                    is_pdf = href.lower().endswith('.pdf') or '/pdf/' in href.lower()
                    button_text = button.get_text().strip().lower()
                    
                    # Look for annual report keywords
                    report_keywords = [
                        'annual report', 'annual-report', 'financial report', 
                        'financial-report', 'annual financial', 'jahresbericht'
                    ]
                    
                    # Try to extract the year from the button text or URL
                    year_match = re.search(r'20\d{2}', href) or re.search(r'20\d{2}', button_text)
                    year = year_match.group(0) if year_match else "Unknown"
                    
                    # Score the button
                    score = 0
                    if is_pdf:
                        score += 3
                    if any(keyword in button_text or keyword in href.lower() for keyword in report_keywords):
                        score += 3
                    if 'download' in button_text or 'download' in href.lower():
                        score += 2
                    if year.isdigit() and int(year) >= 2022:  # Prefer recent reports
                        score += 5
                    elif year.isdigit() and int(year) >= 2020:
                        score += 3
                    
                    if score > 0:  # Only add if it has some relevance
                        pdf_links.append({
                            'url': href,
                            'text': button_text,
                            'year': year,
                            'score': score
                        })
            
            # If still no links found, try common URL patterns
            if not pdf_links:
                # Try to construct direct URLs based on common patterns
                common_patterns = [
                    f"{url.rstrip('/')}/annual-report-{datetime.now().year}.pdf",
                    f"{url.rstrip('/')}/annual-report-{datetime.now().year-1}.pdf",
                    f"{url.rstrip('/')}/annual_report_{datetime.now().year}.pdf",
                    f"{url.rstrip('/')}/annual_report_{datetime.now().year-1}.pdf",
                    f"{url.rstrip('/')}/financial-report-{datetime.now().year}.pdf",
                    f"{url.rstrip('/')}/financial-report-{datetime.now().year-1}.pdf"
                ]
                
                for pattern_url in common_patterns:
                    try:
                        # Check if URL exists
                        head_response = requests.head(pattern_url, headers=self.headers, timeout=self.request_timeout)
                        
                        # Handle 202 status code
                        if head_response.status_code == 202:
                            print(f"Request accepted, waiting for processing (status code 202)")
                            for attempt in range(3):
                                print(f"Waiting 5 seconds before retry (attempt {attempt+1}/3)...")
                                time.sleep(5)
                                head_response = requests.head(pattern_url, headers=self.headers, timeout=self.request_timeout)
                                if head_response.status_code == 200:
                                    break
                        
                        if head_response.status_code == 200:
                            year_match = re.search(r'20\d{2}', pattern_url)
                            year = year_match.group(0) if year_match else str(datetime.now().year)
                            
                            pdf_links.append({
                                'url': pattern_url,
                                'text': f"Annual Report {year}",
                                'year': year,
                                'score': 4  # Medium-high score for pattern-matched URLs
                            })
                    except Exception as e:
                        print(f"Error checking pattern URL {pattern_url}: {e}")
                        continue
            
            # Company-specific patterns based on the companies in the list
            domain = urlparse(url).netloc
            company_patterns = []
            
            # Siemens pattern
            if 'siemens.com' in domain:
                company_patterns = [
                    f"https://www.siemens.com/applications/b09c49eb-3a14-73b3-9f71-e30e3c2dfdbd/assets/pdfs/en/Siemens_Report_FY{datetime.now().year}.pdf",
                    f"https://www.siemens.com/applications/b09c49eb-3a14-73b3-9f71-e30e3c2dfdbd/assets/pdfs/en/Siemens_Report_FY{datetime.now().year-1}.pdf",
                    f"https://assets.new.siemens.com/siemens/assets/api/uuid:ae46683e-14dd-4455-a882-09d4184457c7/Annual-Financial-Report-FY{datetime.now().year}.pdf",
                    f"https://assets.new.siemens.com/siemens/assets/api/uuid:ae46683e-14dd-4455-a882-09d4184457c7/Annual-Financial-Report-FY{datetime.now().year-1}.pdf"
                ]
            # Vodafone pattern
            elif 'vodafone.com' in domain:
                company_patterns = [
                    f"https://investors.vodafone.com/sites/vodafone-ir/files/vodafone/report-{datetime.now().year}/vodafone-annual-report-{datetime.now().year}.pdf",
                    f"https://investors.vodafone.com/sites/vodafone-ir/files/vodafone/report-{datetime.now().year-1}/vodafone-annual-report-{datetime.now().year-1}.pdf",
                    f"https://www.vodafone.com/sites/default/files/pdfs/annual-report-{datetime.now().year}.pdf",
                    f"https://www.vodafone.com/sites/default/files/pdfs/annual-report-{datetime.now().year-1}.pdf"
                ]
            # British American Tobacco pattern
            elif 'bat.com' in domain:
                company_patterns = [
                    f"https://www.bat.com/group/sites/uk__9d9kcy.nsf/vwPagesWebLive/DO9DCL3B/$FILE/medMD9BH3RJ.pdf",
                    f"https://www.bat.com/group/sites/uk__9d9kcy.nsf/vwPagesWebLive/DO9DCL3B/$FILE/medMD9BH3RJ.pdf?openelement",
                    f"https://www.bat.com/annualreport",
                    f"https://www.bat.com/ar/{datetime.now().year}",
                    f"https://www.bat.com/ar/{datetime.now().year-1}"
                ]
            # Novartis pattern
            elif 'novartis.com' in domain:
                company_patterns = [
                    f"https://www.novartis.com/sites/novartis_com/files/novartis-annual-report-{datetime.now().year}.pdf",
                    f"https://www.novartis.com/sites/novartis_com/files/novartis-annual-report-{datetime.now().year-1}.pdf",
                    f"https://www.novartis.com/investors/financial-data/annual-reports"
                ]
            # ENI pattern
            elif 'eni.com' in domain:
                company_patterns = [
                    f"https://www.eni.com/assets/documents/eng/reports/annual-report-{datetime.now().year}.pdf",
                    f"https://www.eni.com/assets/documents/eng/reports/annual-report-{datetime.now().year-1}.pdf",
                    f"https://www.eni.com/assets/documents/eng/investor/annual-report-{datetime.now().year}.pdf",
                    f"https://www.eni.com/assets/documents/eng/investor/annual-report-{datetime.now().year-1}.pdf"
                ]
            # Mercedes-Benz pattern
            elif 'mercedes-benz.com' in domain:
                company_patterns = [
                    f"https://group.mercedes-benz.com/documents/investors/reports/annual-report-{datetime.now().year}-mercedes-benz.pdf",
                    f"https://group.mercedes-benz.com/documents/investors/reports/annual-report-{datetime.now().year-1}-mercedes-benz.pdf",
                    f"https://group.mercedes-benz.com/investors/reports/annual-reports/annual-report-{datetime.now().year}.pdf",
                    f"https://group.mercedes-benz.com/investors/reports/annual-reports/annual-report-{datetime.now().year-1}.pdf"
                ]
            # FCC pattern (Spanish construction company)
            elif 'fcc.es' in domain or 'fccco.com' in domain:
                company_patterns = [
                    f"https://www.fcc.es/documents/21301/12598296/Informe_Anual_Integrado_{datetime.now().year}_FCC_EN.pdf",
                    f"https://www.fcc.es/documents/21301/12598296/Informe_Anual_Integrado_{datetime.now().year-1}_FCC_EN.pdf",
                    f"https://www.fcc.es/documents/21301/12598296/Informe_Anual_{datetime.now().year}_EN.pdf",
                    f"https://www.fcc.es/documents/21301/12598296/Informe_Anual_{datetime.now().year-1}_EN.pdf"
                ]
            # ACCIONA pattern (Spanish company)
            elif 'acciona.com' in domain:
                company_patterns = [
                    f"https://www.acciona.com/media/financial-reports/annual-report-{datetime.now().year}.pdf",
                    f"https://www.acciona.com/media/financial-reports/annual-report-{datetime.now().year-1}.pdf",
                    f"https://www.acciona.com/shareholders-investors/financial-information/annual-report/",
                    f"https://www.acciona.com/media/3714667/annual-report-{datetime.now().year-1}.pdf"
                ]
            # SECURITAS AB pattern (Swedish company)
            elif 'securitas.com' in domain:
                company_patterns = [
                    f"https://www.securitas.com/en/investors/financial-reports-and-presentations/annual-reports/annual-report-{datetime.now().year}/",
                    f"https://www.securitas.com/en/investors/financial-reports-and-presentations/annual-reports/annual-report-{datetime.now().year-1}/",
                    f"https://www.securitas.com/globalassets/financial-information/annual-reports/securitas_annual_and_sustainability_report_{datetime.now().year}.pdf",
                    f"https://www.securitas.com/globalassets/financial-information/annual-reports/securitas_annual_and_sustainability_report_{datetime.now().year-1}.pdf"
                ]
            # SIGNIFY NV pattern (Dutch company, formerly Philips Lighting)
            elif 'signify.com' in domain:
                company_patterns = [
                    f"https://www.signify.com/static/2023/signify-annual-report-{datetime.now().year}.pdf",
                    f"https://www.signify.com/static/2022/signify-annual-report-{datetime.now().year-1}.pdf",
                    f"https://www.signify.com/global/our-company/investors/financial-reports",
                    f"https://www.signify.com/static/financial-reports/annual-report-{datetime.now().year}.pdf"
                ]
            # ASSA ABLOY AB pattern (Swedish company)
            elif 'assaabloy.com' in domain:
                company_patterns = [
                    f"https://www.assaabloy.com/group/en/investors/reports-and-presentations/annual-report-{datetime.now().year}",
                    f"https://www.assaabloy.com/group/en/investors/reports-and-presentations/annual-report-{datetime.now().year-1}",
                    f"https://www.assaabloy.com/content/dam/assaabloy/group-new/seo/investor-relations/financial-reports/annual-reports/en/ASSA_ABLOY_Annual_Report_{datetime.now().year}.pdf",
                    f"https://www.assaabloy.com/content/dam/assaabloy/group-new/seo/investor-relations/financial-reports/annual-reports/en/ASSA_ABLOY_Annual_Report_{datetime.now().year-1}.pdf"
                ]
                
            # Try each company-specific pattern
            for pattern_url in company_patterns:
                try:
                    # Check if URL exists
                    head_response = requests.head(pattern_url, headers=self.headers, timeout=self.request_timeout)
                    
                    # Handle 202 status code (request accepted but processing)
                    if head_response.status_code == 202:
                        print(f"HEAD request accepted, waiting for processing (status code 202)")
                        # Wait and retry up to 3 times
                        for attempt in range(3):
                            print(f"Waiting 5 seconds before retry (attempt {attempt+1}/3)...")
                            time.sleep(5)
                            head_response = requests.head(pattern_url, headers=self.headers, timeout=self.request_timeout)
                            if head_response.status_code == 200:
                                print("HEAD request processed successfully")
                                break
                            print(f"Still processing (status code {head_response.status_code})")
                    
                    # If HEAD request doesn't work, try GET request
                    if head_response.status_code != 200:
                        print(f"HEAD request failed with status {head_response.status_code}, trying GET request...")
                        get_response = requests.get(pattern_url, headers=self.headers, timeout=self.request_timeout, stream=True)
                        # Close the connection immediately after checking status
                        get_response.close()
                        if get_response.status_code == 200:
                            head_response.status_code = 200  # Override the status code for processing
                            print("GET request successful")
                    
                    if head_response.status_code == 200:
                        year_match = re.search(r'20\d{2}', pattern_url) or re.search(r'FY(\d{4})', pattern_url)
                        year = year_match.group(0) if year_match else str(datetime.now().year)
                        if year.startswith('FY'):
                            year = year[2:]  # Remove FY prefix
                        
                        # Extract company name from domain
                        company_name = domain.split('.')[0]
                        if company_name.startswith('www.'):
                            company_name = company_name[4:]
                        company_name = company_name.capitalize()
                        
                        pdf_links.append({
                            'url': pattern_url,
                            'text': f"{company_name} Annual Report {year}",
                            'year': year,
                            'score': 10  # High score for known patterns
                        })
                except Exception as e:
                    print(f"Error checking URL {pattern_url}: {e}")
                    continue
                    
            # Sort PDF links by score and year
            if pdf_links:
                pdf_links.sort(key=lambda x: (x.get('score', 0), int(x['year']) if x['year'].isdigit() else 0), reverse=True)
            
            return pdf_links
            
        except Exception as e:
            print(f"Error processing page {url}: {e}")
            return []
    
    def find_company_reports(self, company_name):
        """Main method to find annual reports for a company"""
        print(f"\nProcessing: {company_name}")
        
        # Normalize company name for better searching
        normalized_name = self.normalize_company_name(company_name)
        
        # Generate search queries with different search terms
        # Add Europe/European to focus on European results
        search_queries = [
            f"{company_name} annual report pdf",
            f"{normalized_name} european financial report",
            f"{normalized_name} europe investor relations annual report",
            f"{company_name} financial statements EU"
        ]
        
        # Handle special cases for abbreviations/acronyms
        if company_name == "FCC":
            search_queries = [
                "FCC Group Spain annual report pdf",
                "Fomento de Construcciones y Contratas annual report",
                "FCC Spain financial report",
                "FCC construction Spain investor relations"
            ]
        elif company_name == "ENI S P A":
            search_queries = [
                "ENI SpA Italy annual report pdf",
                "ENI energy company Italy financial report",
                "ENI oil and gas financial statements",
                "ENI SpA investor relations report"
            ]
        
        # Step 1: Find investor relations pages
        ir_pages = []
        for query in search_queries[:2]:  # Try first 2 queries initially
            pages = self.find_investor_relations_page(query)
            ir_pages.extend(pages)
            if pages:  # If we found some results, don't need to try all queries
                break
            time.sleep(random.uniform(2, 3))  # Avoid rate limiting
        
        # If still no results, try remaining queries
        if not ir_pages:
            for query in search_queries[2:]:
                pages = self.find_investor_relations_page(query)
                ir_pages.extend(pages)
                if pages:  # If we found some results, break
                    break
                time.sleep(random.uniform(2, 3))  # Avoid rate limiting
        
        # Add retry with more specific European terms if we still have no results
        if not ir_pages:
            retry_queries = [
                f"{company_name} European Union annual report",
                f"{normalized_name} EU headquarters financial report",
                f"{company_name} consolidated annual report Europe"
            ]
            
            for query in retry_queries:
                pages = self.find_investor_relations_page(query)
                ir_pages.extend(pages)
                if pages:
                    break
                time.sleep(random.uniform(2, 3))
        
        if not ir_pages:
            print(f"Could not find investor relations pages for {company_name}")
            return []
        
        # Remove duplicates from IR pages
        seen_urls = set()
        unique_ir_pages = []
        for page in ir_pages:
            if page['url'] not in seen_urls:
                seen_urls.add(page['url'])
                unique_ir_pages.append(page)
        
        # Step 2: Extract PDF links from each page
        all_pdf_links = []
        
        # First check the most promising IR pages (first 3)
        for page in unique_ir_pages[:3]:
            pdf_links = self.extract_pdf_links(page['url'])
            all_pdf_links.extend(pdf_links)
            
            # If we found good PDF links (with scores), we might not need to check more pages
            if pdf_links and any(link.get('score', 0) >= 8 for link in pdf_links):
                break
                
            time.sleep(random.uniform(2, 3))  # Avoid rate limiting
        
        # Step 3: Sort by score and year, then deduplicate
        seen_urls = set()
        unique_pdfs = []
        
        # Sort by score (if available) and then by year
        sorted_pdfs = sorted(
            all_pdf_links, 
            key=lambda x: (x.get('score', 0), int(x['year']) if x['year'].isdigit() else 0), 
            reverse=True
        )
        
        # Deduplicate
        for pdf in sorted_pdfs:
            if pdf['url'] not in seen_urls:
                seen_urls.add(pdf['url'])
                unique_pdfs.append(pdf)
        
        return unique_pdfs
        
    def try_known_company_patterns(self, company_name):
        """Try known URL patterns for specific companies"""
        print(f"Trying known patterns for {company_name}")
        pdf_links = []
        
        # Dictionary of company-specific patterns
        company_patterns = {
            "SIEMENS": [
                f"https://www.siemens.com/applications/b09c49eb-3a14-73b3-9f71-e30e3c2dfdbd/assets/pdfs/en/Siemens_Report_FY{datetime.now().year}.pdf",
                f"https://www.siemens.com/applications/b09c49eb-3a14-73b3-9f71-e30e3c2dfdbd/assets/pdfs/en/Siemens_Report_FY{datetime.now().year-1}.pdf"
            ],
            "VODAFONE GROUP PLC": [
                f"https://investors.vodafone.com/sites/vodafone-ir/files/vodafone/report-{datetime.now().year}/vodafone-annual-report-{datetime.now().year}.pdf",
                f"https://investors.vodafone.com/sites/vodafone-ir/files/vodafone/report-{datetime.now().year-1}/vodafone-annual-report-{datetime.now().year-1}.pdf"
            ],
            "BRITISH AMERICAN TOBACCO PLC": [
                f"https://www.bat.com/ar/{datetime.now().year}",
                f"https://www.bat.com/ar/{datetime.now().year-1}"
            ],
            "NOVARTIS AG": [
                f"https://www.novartis.com/sites/novartis_com/files/novartis-annual-report-{datetime.now().year}.pdf",
                f"https://www.novartis.com/sites/novartis_com/files/novartis-annual-report-{datetime.now().year-1}.pdf"
            ],
            "ENI S P A": [
                f"https://www.eni.com/assets/documents/eng/reports/annual-report-{datetime.now().year}.pdf",
                f"https://www.eni.com/assets/documents/eng/reports/annual-report-{datetime.now().year-1}.pdf"
            ],
            "MERCEDES-BENZ GROUP": [
                f"https://group.mercedes-benz.com/documents/investors/reports/annual-report-{datetime.now().year}-mercedes-benz.pdf",
                f"https://group.mercedes-benz.com/documents/investors/reports/annual-report-{datetime.now().year-1}-mercedes-benz.pdf"
            ],
            "FCC": [
                f"https://www.fcc.es/documents/21301/12598296/Informe_Anual_Integrado_{datetime.now().year}_FCC_EN.pdf",
                f"https://www.fcc.es/documents/21301/12598296/Informe_Anual_Integrado_{datetime.now().year-1}_FCC_EN.pdf"
            ],
            "ACCIONA": [
                f"https://www.acciona.com/media/financial-reports/annual-report-{datetime.now().year}.pdf",
                f"https://www.acciona.com/media/financial-reports/annual-report-{datetime.now().year-1}.pdf"
            ],
            "SECURITAS AB": [
                f"https://www.securitas.com/globalassets/financial-information/annual-reports/securitas_annual_and_sustainability_report_{datetime.now().year}.pdf",
                f"https://www.securitas.com/globalassets/financial-information/annual-reports/securitas_annual_and_sustainability_report_{datetime.now().year-1}.pdf"
            ],
            "SIGNIFY NV": [
                f"https://www.signify.com/static/{datetime.now().year}/signify-annual-report-{datetime.now().year}.pdf",
                f"https://www.signify.com/static/{datetime.now().year-1}/signify-annual-report-{datetime.now().year-1}.pdf"
            ],
            "ASSA ABLOY AB": [
                f"https://www.assaabloy.com/content/dam/assaabloy/group-new/seo/investor-relations/financial-reports/annual-reports/en/ASSA_ABLOY_Annual_Report_{datetime.now().year}.pdf",
                f"https://www.assaabloy.com/content/dam/assaabloy/group-new/seo/investor-relations/financial-reports/annual-reports/en/ASSA_ABLOY_Annual_Report_{datetime.now().year-1}.pdf"
            ]
        }
        
        # Try to match company name with patterns
        matched_company = None
        for pattern_company in company_patterns.keys():
            if company_name.upper() in pattern_company or pattern_company in company_name.upper():
                matched_company = pattern_company
                break
        
        # If company matches a known pattern, try those URLs
        if matched_company:
            print(f"Matched company pattern: {matched_company}")
            for pattern_url in company_patterns[matched_company]:
                try:
                    # Check if URL exists
                    head_response = requests.head(pattern_url, headers=self.headers, timeout=self.request_timeout)
                    
                    # Handle 202 status code
                    if head_response.status_code == 202:
                        for attempt in range(3):
                            print(f"Waiting 5 seconds before retry (attempt {attempt+1}/3)...")
                            time.sleep(5)
                            head_response = requests.head(pattern_url, headers=self.headers, timeout=self.request_timeout)
                            if head_response.status_code == 200:
                                break
                    
                    # If HEAD request doesn't work, try GET
                    if head_response.status_code != 200:
                        get_response = requests.get(pattern_url, headers=self.headers, timeout=self.request_timeout, stream=True)
                        get_response.close()
                        if get_response.status_code == 200:
                            head_response.status_code = 200
                    
                    if head_response.status_code == 200:
                        # Extract year from URL
                        year_match = re.search(r'20\d{2}', pattern_url)
                        year = year_match.group(0) if year_match else str(datetime.now().year)
                        
                        pdf_links.append({
                            'url': pattern_url,
                            'text': f"{matched_company} Annual Report {year}",
                            'year': year,
                            'score': 10  # High score for direct pattern match
                        })
                        print(f"Found direct match: {pattern_url}")
                except Exception as e:
                    print(f"Error checking pattern URL {pattern_url}: {e}")
        
        return pdf_links
    
    def process_company_list(self, companies):
        """Process a list of companies and save results to CSV"""
        results = []
        
        for idx, company in enumerate(companies):
            print(f"Processing company {idx+1}/{len(companies)}: {company}")
            
            # Try to find reports with up to 3 attempts
            attempt = 1
            max_attempts = 3
            pdf_links = []
            
            while attempt <= max_attempts and not pdf_links:
                print(f"Attempt {attempt}/{max_attempts} for {company}")
                
                # Adjust search strategy based on attempt number
                if attempt == 1:
                    # Standard search
                    pdf_links = self.find_company_reports(company)
                elif attempt == 2:
                    # Try with more specific European terms
                    print(f"Retry with more specific European search terms")
                    normalized_name = self.normalize_company_name(company)
                    
                    # Create EU-specific search query
                    query = f"{normalized_name} europe annual financial report pdf"
                    print(f"Searching for: {query}")
                    
                    ir_pages = self.search_duckduckgo(query)
                    for page in ir_pages[:3]:  # Check top 3 results
                        links = self.extract_pdf_links(page['url'])
                        pdf_links.extend(links)
                        if links:  # If we found links, we can stop
                            break
                        time.sleep(random.uniform(2, 3))
                else:
                    # Try direct known patterns for this company
                    print(f"Trying direct known patterns for {company}")
                    pdf_links = self.try_known_company_patterns(company)
                
                attempt += 1
                
                # Add a pause between attempts
                if not pdf_links and attempt <= max_attempts:
                    delay = random.uniform(3, 5)
                    print(f"No results found. Waiting {delay:.1f} seconds before next attempt...")
                    time.sleep(delay)
            
            # Add financial report (FIN_REP) entry
            if pdf_links:
                # Sort by score and year to get the best match first
                pdf_links = sorted(
                    pdf_links,
                    key=lambda x: (x.get('score', 0), int(x['year']) if x['year'].isdigit() else 0),
                    reverse=True
                )
                
                # Print found reports for debugging
                print(f"Found {len(pdf_links)} reports for {company}:")
                for i, pdf in enumerate(pdf_links[:5]):
                    print(f"  {i+1}. {pdf['url']} (Year: {pdf['year']}, Score: {pdf.get('score', 0)})")
                
                # Add the first link as FIN_REP
                results.append({
                    'COMPANY': company,
                    'TYPE': 'FIN_REP',
                    'SRC': pdf_links[0]['url'],
                    'REFYEAR': pdf_links[0]['year']
                })
                
                # Add additional sources as OTHER (up to 5)
                for i, pdf in enumerate(pdf_links[1:6]):
                    if pdf['url'] != pdf_links[0]['url']:  # Avoid duplicates
                        results.append({
                            'COMPANY': company,
                            'TYPE': 'OTHER',
                            'SRC': pdf['url'],
                            'REFYEAR': pdf['year']
                        })
            else:
                # If no reports found after all attempts, add empty entry
                print(f"No reports found for {company} after {max_attempts} attempts")
                results.append({
                    'COMPANY': company,
                    'TYPE': 'FIN_REP',
                    'SRC': '',
                    'REFYEAR': ''
                })
            
            # Save intermediate results after each company
            self.save_to_csv(results, f"{self.results_folder}/financial_reports.csv")
            print(f"Completed processing {company}, found {sum(1 for r in results if r['COMPANY'] == company and r['SRC'])} reports")
            
            # Add a pause between companies
            if idx < len(companies) - 1:
                delay = random.uniform(3, 5)
                print(f"Waiting {delay:.1f} seconds before next company...")
                time.sleep(delay)
        
        return results
        
    def save_to_csv(self, data, filename):
        """Save results to CSV file"""
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(filename), exist_ok=True)
        
        # Write to CSV
        with open(filename, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=['COMPANY', 'TYPE', 'SRC', 'REFYEAR'])
            writer.writeheader()
            writer.writerows(data)
        
        print(f"Results saved to {filename}")
        
    def format_to_discovery_csv(self, input_file, template_file, output_file):
        """
        Format the results to match the required discovery.csv format
        
        Args:
            input_file: CSV with company reports
            template_file: Discovery template CSV
            output_file: Output file path
        """
        # Check if files exist
        if not os.path.exists(input_file):
            print(f"Error: Input file {input_file} not found")
            return
            
        if not os.path.exists(template_file):
            print(f"Error: Template file {template_file} not found")
            return
            
        # Read files
        df_input = pd.read_csv(input_file)
        df_template = pd.read_csv(template_file)
        
        # Create results dataframe
        results = []
        
        # Process each company in the template
        for _, row in df_template.iterrows():
            company_name = row['NAME']
            company_id = row.get('ID', '')  # Get ID if exists, otherwise use empty string
            
            # Find reports for this company
            company_reports = df_input[df_input['COMPANY'] == company_name]
            
            # Add financial report row (FIN_REP)
            fin_rep = company_reports[company_reports['TYPE'] == 'FIN_REP'].iloc[0] if not company_reports[company_reports['TYPE'] == 'FIN_REP'].empty else None
            
            results.append({
                'ID': company_id,
                'NAME': company_name,
                'TYPE': 'FIN_REP',
                'SRC': fin_rep['SRC'] if fin_rep is not None else '',
                'REFYEAR': fin_rep['REFYEAR'] if fin_rep is not None else ''
            })
            
            # Add 5 OTHER rows
            other_reports = company_reports[company_reports['TYPE'] == 'OTHER']
            
            for i in range(5):
                if i < len(other_reports):
                    results.append({
                        'ID': company_id,
                        'NAME': company_name,
                        'TYPE': 'OTHER',
                        'SRC': other_reports.iloc[i]['SRC'],
                        'REFYEAR': other_reports.iloc[i]['REFYEAR']
                    })
                else:
                    # Add empty rows to make 6 rows total per company
                    results.append({
                        'ID': company_id,
                        'NAME': company_name,
                        'TYPE': 'OTHER',
                        'SRC': '',
                        'REFYEAR': ''
                    })
        
        # Write to CSV
        with open(output_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=['ID', 'NAME', 'TYPE', 'SRC', 'REFYEAR'])
            writer.writeheader()
            writer.writerows(results)
        
        print(f"Discovery CSV saved to {output_file}")
