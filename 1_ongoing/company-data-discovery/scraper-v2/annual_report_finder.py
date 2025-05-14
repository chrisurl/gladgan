# annual_report_finder.py
import argparse
import json
import csv
import time
import random
import os
import sys
from google_search import search_google
from link_processor import is_pdf_link, extract_year, extract_pdf_links
from result_ranker import rank_results
from api_tracker import APITracker
from config_handler import get_api_credentials, get_setting, CONFIG_FILE

def process_company(company_name, max_results=10, api_key=None, search_engine_id=None):
    """Process a single company to find its annual reports"""
    print(f"\nProcessing: {company_name}")
    
    # Check API quota first
    tracker = APITracker()
    daily_limit = get_setting('daily_api_limit', None, 100)
    if not tracker.can_make_request(daily_limit):
        print(f"Daily API limit reached ({daily_limit} requests). Try again tomorrow.")
        return []
    
    # Search for company annual reports
    urls = search_google(company_name, max_results, api_key, search_engine_id)
    
    if not urls:
        print(f"No search results found for {company_name}")
        return []
    
    processed_results = []
    
    # Process each search result
    for url in urls:
        # Check if it's a PDF
        is_pdf = is_pdf_link(url)
        year = extract_year(url)
        
        processed_results.append({
            'url': url,
            'is_pdf': is_pdf,
            'year': year,
            'source': 'search'
        })
        
        # If not a PDF, try to extract PDFs from the page
        if not is_pdf:
            print(f"  Extracting PDFs from: {url}")
            pdf_links = extract_pdf_links(url)
            
            for pdf in pdf_links:
                processed_results.append({
                    'url': pdf['url'],
                    'text': pdf.get('text', ''),
                    'is_pdf': True,
                    'year': pdf.get('year'),
                    'source': f"extracted from {url}"
                })
        
        # Add a small delay
        time.sleep(random.uniform(0.5, 1.5))
    
    # Rank results
    ranked_results = rank_results(processed_results)
    
    return ranked_results

def main():
    parser = argparse.ArgumentParser(description='Find company annual reports using Google API')
    parser.add_argument('--companies', nargs='+', help='List of company names')
    parser.add_argument('--input-file', help='CSV file with company names')
    parser.add_argument('--output', help='Output JSON file')
    parser.add_argument('--max-results', type=int, help='Maximum search results to process')
    parser.add_argument('--api-key', help='Google API Key (overrides config file)')
    parser.add_argument('--search-engine-id', help='Google Search Engine ID (overrides config file)')
    parser.add_argument('--dry-run', action='store_true', help='Check API quota without making requests')
    parser.add_argument('--init-config', action='store_true', help='Initialize config.json file and exit')
    
    args = parser.parse_args()
    
    # Initialize config file if requested
    if args.init_config:
        from config_handler import create_default_config
        create_default_config()
        print(f"Please edit {CONFIG_FILE} with your API credentials.")
        return
    
    # Get API credentials from config or args
    api_key, search_engine_id = get_api_credentials(args)
    
    # Just check quota and exit if dry run
    if args.dry_run:
        tracker = APITracker()
        daily_limit = get_setting('daily_api_limit', None, 100)
        quota = tracker.get_remaining_quota(daily_limit)
        print(f"Remaining API quota for today: {quota}/{daily_limit}")
        return
    
    # Check if we have valid credentials
    if not api_key or not search_engine_id:
        print("Error: Google API key and Search Engine ID are required.")
        print(f"Please edit {CONFIG_FILE} or provide them as command line arguments.")
        return
    
    # Get other settings
    max_results = get_setting('max_results_per_query', args.max_results, 10)
    output_file = get_setting('default_output_file', args.output, 'results.json')
    
    # Get companies to process
    companies = []
    if args.companies:
        companies = args.companies
    elif args.input_file:
        if not os.path.exists(args.input_file):
            print(f"Error: Input file {args.input_file} not found.")
            return
            
        # Read companies from CSV file
        with open(args.input_file, 'r') as f:
            reader = csv.reader(f)
            next(reader, None)  # Skip header
            for row in reader:
                if row:  # Skip empty rows
                    companies.append(row[0])
    else:
        print("Error: Please provide either --companies or --input-file")
        return
    
    # Check if we have enough quota
    tracker = APITracker()
    daily_limit = get_setting('daily_api_limit', None, 100)
    quota = tracker.get_remaining_quota(daily_limit)
    
    if quota < len(companies):
        print(f"Warning: Not enough API quota left for all companies.")
        print(f"Remaining quota: {quota}, Companies to process: {len(companies)}")
        
        proceed = input("Do you want to process as many as possible? (y/n): ")
        if proceed.lower() != 'y':
            print("Aborted.")
            return
    
    all_results = {}
    processed_count = 0
    
    for company in companies:
        # Check if we still have quota
        if not tracker.can_make_request(daily_limit):
            print(f"Daily API limit reached ({daily_limit} requests). Try again tomorrow.")
            break
        
        results = process_company(company, max_results, api_key, search_engine_id)
        if results:  # Only count if we got results (if API limit wasn't reached)
            all_results[company] = results
            processed_count += 1
            
            # Print top 3 results
            print(f"\nTop results for {company}:")
            for i, result in enumerate(results[:3], 1):
                pdf_status = "PDF" if result.get('is_pdf') else "Web Page"
                year = result.get('year', 'Unknown')
                print(f"  {i}. [{pdf_status}] {result['url']}")
                print(f"     Year: {year}, Score: {result.get('score', 0)}")
    
    # Save results to file
    with open(output_file, 'w') as f:
        json.dump(all_results, f, indent=2)
    
    print(f"\nProcessed {processed_count} out of {len(companies)} companies.")
    print(f"Results saved to {output_file}")
    
    # Report remaining quota
    remaining = tracker.get_remaining_quota(daily_limit)
    print(f"Remaining API quota for today: {remaining}/{daily_limit}")

if __name__ == "__main__":
    main()