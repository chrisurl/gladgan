import os
import pandas as pd
import zipfile
import shutil
from company_report_finder import FinancialReportFinder
from discovery_csv_generator import format_discovery_csv

def create_submission_zip(discovery_csv, description_docx, code_zip):
    """
    Create the submission.zip file according to the challenge requirements
    
    Args:
        discovery_csv: Path to the discovery.csv file
        description_docx: Path to the description docx file
        code_zip: Path to the code.zip file
    """
    # Create submission.zip
    with zipfile.ZipFile('submission.zip', 'w') as submission_zip:
        # Add discovery.csv
        submission_zip.write(discovery_csv, arcname='discovery.csv')
        
        # Add description docx
        submission_zip.write(description_docx, arcname='discovery_approach_description.docx')
        
        # Add code.zip
        submission_zip.write(code_zip, arcname='code.zip')
    
    print("Submission.zip created successfully")

def create_code_zip():
    """
    Create the code.zip file containing all the Python scripts
    """
    with zipfile.ZipFile('code.zip', 'w') as code_zip:
        # Add all Python files
        for file in os.listdir():
            if file.endswith('.py'):
                code_zip.write(file)
    
    print("Code.zip created successfully")

def main():
    # Create folders
    os.makedirs('results', exist_ok=True)
    
    # Step 1: Read the company list from the discovery-subset.csv
    input_file = "challenge/discovery-subset.csv"
    
    if not os.path.exists(input_file):
        print(f"Error: Input file {input_file} not found")
        return
    
    # Read company names
    try:
        df = pd.read_csv(input_file)
        companies = df['NAME'].tolist()
        
        print(f"Processing {len(companies)} companies...")
        
        # Step 2: Find financial reports for each company
        finder = FinancialReportFinder()
        results = finder.process_company_list(companies)
        
        # Step 3: Format to discovery.csv
        finder.format_to_discovery_csv(
            input_file="results/financial_reports.csv",
            template_file=input_file,
            output_file="discovery.csv"
        )
        
        # Step 4: Create code.zip
        create_code_zip()
        
        # Step 5: Create submission.zip (if description docx exists)
        description_file = "discovery_approach_description.docx"
        if os.path.exists(description_file):
            create_submission_zip(
                discovery_csv="discovery.csv",
                description_docx=description_file,
                code_zip="code.zip"
            )
            print("Submission package created successfully!")
        else:
            print(f"Warning: {description_file} not found. Can't create submission.zip")
            print("Please create the description document before finalizing the submission")
            
    except Exception as e:
        print(f"Error processing companies: {e}")
        import traceback
        traceback.print_exc()
        
    print("Processing complete!")


if __name__ == "__main__":
    main()
