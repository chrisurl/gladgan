#!/usr/bin/env python3
"""
Financial Reports Discovery
--------------------------
This script finds financial reports for companies listed in the discovery-subset.csv
file and formats the results according to the challenge requirements.

Usage:
    python fixed_main.py [--input FILE] [--output FILE] [--batch-size INT] [--single-company NAME]
"""

import os
import sys
import argparse
import time
from datetime import datetime
import pandas as pd
import zipfile
import shutil

# Import our fixed version
from company_report_finder_fixed import FinancialReportFinder


def setup_args():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Financial Reports Discovery")
    parser.add_argument('--input', type=str, default='challenge/discovery-subset.csv',
                        help='Input CSV file path')
    parser.add_argument('--output', type=str, default='discovery.csv',
                        help='Output discovery CSV file path')
    parser.add_argument('--batch-size', type=int, default=5,
                        help='Number of companies to process in batch')
    parser.add_argument('--single-company', type=str, default='',
                        help='Process only a single company by name')
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
                print(f"=" * 80)
                print(f"STARTING COMPANY: {company}")
                print(f"Current time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
                print(f"=" * 80)
                
                # Process one company at a time for better handling
                company_results = finder.process_company_list([company])
                batch_results.extend(company_results)
                
                # Update overall results
                results.extend(company_results)
                
                # Save intermediate results
                finder.save_to_csv(results, f"{output_dir}/financial_reports.csv")
                
                print(f"=" * 80)
                print(f"COMPLETED COMPANY: {company}")
                print(f"Current time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
                print(f"=" * 80)
                
            except Exception as e:
                print(f"[ERROR] Error processing company {company}: {str(e)}")
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


def create_code_zip():
    """Create the code.zip file containing all the Python scripts"""
    with zipfile.ZipFile('code.zip', 'w') as code_zip:
        # Add all Python files
        for file in os.listdir():
            if file.endswith('.py'):
                code_zip.write(file)
    
    print("Code.zip created successfully")


def create_submission_zip(discovery_csv, description_docx, code_zip):
    """Create the submission.zip file according to the challenge requirements"""
    # Create submission.zip
    with zipfile.ZipFile('submission.zip', 'w') as submission_zip:
        # Add discovery.csv
        submission_zip.write(discovery_csv, arcname='discovery.csv')
        
        # Add description docx
        submission_zip.write(description_docx, arcname='discovery_approach_description.docx')
        
        # Add code.zip
        submission_zip.write(code_zip, arcname='code.zip')
    
    print("Submission.zip created successfully")


def process_single_company(company_name):
    """Process a single company for testing"""
    print(f"=" * 80)
    print(f"Testing with a single company: {company_name}")
    print(f"=" * 80)
    
    finder = FinancialReportFinder()
    
    # First test the find_company_reports method
    print("Testing find_company_reports method...")
    reports = finder.find_company_reports(company_name)
    
    print(f"\nFound {len(reports)} reports for {company_name}:")
    for i, report in enumerate(reports):
        print(f"{i+1}. {report['url']} (Year: {report['year']}, Score: {report.get('score', 0)})")
    
    # Then test the try_known_company_patterns method
    print("\nTesting try_known_company_patterns method...")
    pattern_reports = finder.try_known_company_patterns(company_name)
    
    print(f"\nFound {len(pattern_reports)} pattern reports for {company_name}:")
    for i, report in enumerate(pattern_reports):
        print(f"{i+1}. {report['url']} (Year: {report['year']}, Score: {report.get('score', 0)})")
    
    print(f"\nTest complete for {company_name}")
    
    # Save reports to CSV
    if reports:
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
        os.makedirs('results', exist_ok=True)
        finder.save_to_csv(results, "results/single_company_test.csv")
        print(f"Results saved to results/single_company_test.csv")
    
    return results


def main():
    """Main function"""
    # Parse arguments
    args = setup_args()
    
    print("=" * 80)
    print("Financial Reports Discovery")
    print("=" * 80)
    print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Create results folder
    os.makedirs('results', exist_ok=True)
    
    # Check if we're processing a single company
    if args.single_company:
        process_single_company(args.single_company)
        return 0
    
    print(f"Input file: {args.input}")
    print(f"Output file: {args.output}")
    print(f"Batch size: {args.batch_size}")
    print("=" * 80)
    
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
            
            # Create code.zip
            create_code_zip()
            
            # Create submission.zip if description docx exists
            description_file = "discovery_approach_description.docx"
            if os.path.exists(description_file):
                create_submission_zip(
                    discovery_csv=args.output,
                    description_docx=description_file,
                    code_zip="code.zip"
                )
                print("Submission package created successfully!")
            else:
                print(f"Warning: {description_file} not found. Can't create submission.zip")
                print("Please create the description document before finalizing the submission")
            
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
    sys.exit(main())#!/usr/bin/env python3
"""
Financial Reports Discovery
--------------------------
This script finds financial reports for companies listed in the discovery-subset.csv
file and formats the results according to the challenge requirements.

Usage:
    python fixed_main.py [--input FILE] [--output FILE] [--batch-size INT]
"""

import os
import sys
import argparse
import time
from datetime import datetime
import pandas as pd
import zipfile
import shutil

# Import our fixed version
from company_report_finder_fixed import FinancialReportFinder


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


def create_code_zip():
    """Create the code.zip file containing all the Python scripts"""
    with zipfile.ZipFile('code.zip', 'w') as code_zip:
        # Add all Python files
        for file in os.listdir():
            if file.endswith('.py'):
                code_zip.write(file)
    
    print("Code.zip created successfully")


def create_submission_zip(discovery_csv, description_docx, code_zip):
    """Create the submission.zip file according to the challenge requirements"""
    # Create submission.zip
    with zipfile.ZipFile('submission.zip', 'w') as submission_zip:
        # Add discovery.csv
        submission_zip.write(discovery_csv, arcname='discovery.csv')
        
        # Add description docx
        submission_zip.write(description_docx, arcname='discovery_approach_description.docx')
        
        # Add code.zip
        submission_zip.write(code_zip, arcname='code.zip')
    
    print("Submission.zip created successfully")


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
            
            # Create code.zip
            create_code_zip()
            
            # Create submission.zip if description docx exists
            description_file = "discovery_approach_description.docx"
            if os.path.exists(description_file):
                create_submission_zip(
                    discovery_csv=args.output,
                    description_docx=description_file,
                    code_zip="code.zip"
                )
                print("Submission package created successfully!")
            else:
                print(f"Warning: {description_file} not found. Can't create submission.zip")
                print("Please create the description document before finalizing the submission")
            
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
