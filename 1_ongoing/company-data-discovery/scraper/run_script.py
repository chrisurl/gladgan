#!/usr/bin/env python3
"""
Financial Reports Discovery
--------------------------
This script finds financial reports for companies listed in the discovery-subset.csv
file and formats the results according to the challenge requirements.

Usage:
    python run.py [--input FILE] [--output FILE] [--batch-size INT]

Options:
    --input FILE      Input CSV file path [default: challenge/discovery-subset.csv]
    --output FILE     Output discovery CSV file path [default: discovery.csv]
    --batch-size INT  Number of companies to process in batch [default: 5]
    --help           Show this help message
"""

import os
import sys
import argparse
import time
from datetime import datetime
from company_report_finder import FinancialReportFinder
from discovery_csv_generator import format_discovery_csv
import pandas as pd


def setup_args():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Financial Reports Discovery")
    parser.add_argument('--input', type=str, default='challenge/discovery-subset.csv',
                        help='Input CSV file path')
    parser.add_argument('--output', type=str, default='discovery.csv',
                        help='Output discovery CSV file path')
    parser.add_argument('--batch-size', type=int, default=5,
                        help='Number of companies to process in batch')
    return parser.parse_args()


def process_batch(companies, finder, batch_size, output_dir):
    """Process companies in batches to avoid IP blocks"""
    total_companies = len(companies)
    results = []
    
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Process in batches
    for i in range(0, total_companies, batch_size):
        batch = companies[i:min(i+batch_size, total_companies)]
        print(f"\nProcessing batch {i//batch_size + 1} of {(total_companies-1)//batch_size + 1}")
        print(f"Companies in this batch: {', '.join(batch)}")
        
        # Process this batch
        batch_results = []
        for company in batch:
            try:
                # Process one company at a time for better handling
                company_results = finder.process_company_list([company])
                batch_results.extend(company_results)
                
                # Update overall results
                results.extend(company_results)
                
                # Save intermediate results
                finder.save_to_csv(results, f"{output_dir}/financial_reports.csv")
                
            except Exception as e:
                print(f"Error processing company {company}: {e}")
                import traceback
                traceback.print_exc()
                
                # Add empty result for this company to maintain structure
                results.append({
                    'COMPANY': company,
                    'TYPE': 'FIN_REP',
                    'SRC': '',
                    'REFYEAR': ''
                })
                
                # Save the results even after error
                finder.save_to_csv(results, f"{output_dir}/financial_reports.csv")
        
        # Save batch results
        batch_filename = f"{output_dir}/batch_{i//batch_size + 1}.csv"
        finder.save_to_csv(batch_results, batch_filename)
        
        # Pause between batches (except for the last one)
        if i + batch_size < total_companies:
            pause_minutes = 3
            pause_seconds = pause_minutes * 60
            print(f"\nPausing for {pause_minutes} minutes before next batch...")
            
            # Show a countdown
            for remaining in range(pause_seconds, 0, -30):
                print(f"  {remaining//60} minutes {remaining%60} seconds remaining...")
                time.sleep(30)
    
    return results


def main():
    """Main function"""
    # Parse arguments
    args = setup_args()
    
    print("=" * 80)
    print("Financial Reports Discovery")
    print("=" * 80)
    print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Input file: {args.input}")
    print(f"Output file: {args.output}")
    print(f"Batch size: {args.batch_size}")
    print("=" * 80)
    
    # Create results folder
    os.makedirs('results', exist_ok=True)
    
    # Check if input file exists
    if not os.path.exists(args.input):
        print(f"Error: Input file {args.input} not found")
        return 1
    
    try:
        # Read company names
        df = pd.read_csv(args.input)
        if 'NAME' not in df.columns:
            print(f"Error: Input file {args.input} does not contain a 'NAME' column")
            return 1
            
        companies = df['NAME'].tolist()
        
        if not companies:
            print("Error: No companies found in the input file")
            return 1
            
        print(f"Processing {len(companies)} companies...")
        print(f"Companies to process: {', '.join(companies)}")
        
        # Initialize finder with increased timeouts
        finder = FinancialReportFinder()
        
        # Process companies in batches with better error handling
        try:
            results = process_batch(companies, finder, args.batch_size, 'results')
            
            # Format to discovery.csv
            finder.format_to_discovery_csv(
                input_file="results/financial_reports.csv",
                template_file=args.input,
                output_file=args.output
            )
            
            # Count successful results
            successful_companies = sum(1 for company in companies if any(r['COMPANY'] == company and r['SRC'] for r in results))
            
            print("\nResults:")
            print(f"- Processed {len(companies)} companies")
            print(f"- Found reports for {successful_companies}/{len(companies)} companies")
            print(f"- Total reports found: {sum(1 for r in results if r['SRC'])}")
            print(f"- Output file: {args.output}")
            
            print("\nProcessing complete!")
            print(f"Finished at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            return 0
            
        except KeyboardInterrupt:
            print("\nProcess interrupted by user")
            print("Saving partial results...")
            
            # Try to save what we have
            if 'results' in locals() and results:
                finder.save_to_csv(results, "results/financial_reports_interrupted.csv")
                print("Partial results saved to results/financial_reports_interrupted.csv")
            
            return 1
            
    except Exception as e:
        print(f"Error processing companies: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
