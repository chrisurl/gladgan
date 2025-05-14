#!/usr/bin/env python3
"""
Test script for company_report_finder_fixed.py

This is a simple script to test the financial report finder with a single company.
It's useful for debugging and fine-tuning the search approach.

Usage:
    python test_company.py COMPANY_NAME

Example:
    python test_company.py "Siemens"
"""

import sys
import time
import os
from datetime import datetime
from company_report_finder_fixed import FinancialReportFinder

def test_company(company_name):
    """Test the financial report finder with a single company"""
    print(f"=" * 80)
    print(f"TESTING COMPANY: {company_name}")
    print(f"Current time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"=" * 80)
    
    # Initialize the finder
    finder = FinancialReportFinder()
    
    # Create results folder
    os.makedirs('results', exist_ok=True)
    
    # Measure execution time
    start_time = time.time()
    
    # Step 1: Test known company patterns
    print("\n1. Testing direct pattern matching...")
    pattern_reports = finder.try_known_company_patterns(company_name)
    
    if pattern_reports:
        print(f"Found {len(pattern_reports)} reports via pattern matching:")
        for i, report in enumerate(pattern_reports):
            print(f"  {i+1}. {report['url']} (Year: {report['year']}, Score: {report.get('score', 0)})")
    else:
        print("No reports found via direct pattern matching.")
    
    # Step 2: Test full company report search
    print("\n2. Testing full search process...")
    reports = finder.find_company_reports(company_name)
    
    if reports:
        print(f"Found {len(reports)} reports via full search:")
        for i, report in enumerate(reports):
            print(f"  {i+1}. {report['url']} (Year: {report['year']}, Score: {report.get('score', 0)})")
        
        # Save results to CSV
        results = []
        results.append({
            'COMPANY': company_name,
            'TYPE': 'FIN_REP',
            'SRC': reports[0]['url'],
            'REFYEAR': reports[0]['year']
        })
        
        # Add additional sources as OTHER (up to 5)
        for i, pdf in enumerate(reports[1:6]):
            if pdf['url'] != reports[0]['url']:  # Avoid duplicates
                results.append({
                    'COMPANY': company_name,
                    'TYPE': 'OTHER',
                    'SRC': pdf['url'],
                    'REFYEAR': pdf['year']
                })
        
        # Save to CSV
        finder.save_to_csv(results, f"results/{company_name.replace(' ', '_')}_test.csv")
        print(f"Results saved to results/{company_name.replace(' ', '_')}_test.csv")
    else:
        print("No reports found via full search.")
    
    # Step 3: Test processing company list
    print("\n3. Testing complete process_company_list...")
    all_results = finder.process_company_list([company_name])
    
    # Calculate execution time
    end_time = time.time()
    duration = end_time - start_time
    minutes, seconds = divmod(duration, 60)
    hours, minutes = divmod(minutes, 60)
    
    print(f"\nTest completed in {int(hours)}h {int(minutes)}m {int(seconds)}s")
    print(f"Current time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    return reports

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Please provide a company name to test.")
        print("Usage: python test_company.py COMPANY_NAME")
        sys.exit(1)
    
    company_name = sys.argv[1]
    test_company(company_name)
