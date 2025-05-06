import pandas as pd
import os
import csv

def format_discovery_csv(input_file, template_file, output_file):
    """
    Format data to match the required discovery.csv format based on the challenge requirements.
    
    Args:
        input_file: CSV file with the extracted financial report links
        template_file: The discovery template CSV with IDs and NAMEs
        output_file: The path to save the formatted discovery.csv
    """
    # Create output directory if it doesn't exist
    os.makedirs(os.path.dirname(output_file) if os.path.dirname(output_file) else '.', exist_ok=True)
    
    # Read input data with company reports
    if os.path.exists(input_file):
        df_reports = pd.read_csv(input_file)
    else:
        print(f"Error: Input file {input_file} not found")
        return
    
    # Read template with IDs and NAMEs
    if os.path.exists(template_file):
        df_template = pd.read_csv(template_file)
    else:
        print(f"Error: Template file {template_file} not found")
        return
    
    # Create results list
    results = []
    
    # For each row in the template
    for _, row in df_template.iterrows():
        company_id = row.get('ID', '')  # Get ID if exists
        company_name = row['NAME']
        
        # Find matching reports for this company
        company_reports = df_reports[df_reports['COMPANY'] == company_name].reset_index(drop=True)
        
        # Add financial report (FIN_REP) row
        results.append({
            'ID': company_id,
            'NAME': company_name,
            'TYPE': 'FIN_REP',
            'SRC': company_reports.loc[0, 'SRC'] if len(company_reports) > 0 else '',
            'REFYEAR': company_reports.loc[0, 'REFYEAR'] if len(company_reports) > 0 else ''
        })
        
        # Add 5 OTHER rows (whether we have data or not)
        for i in range(5):
            idx = i + 1  # Start from 1 to skip the FIN_REP
            results.append({
                'ID': company_id,
                'NAME': company_name,
                'TYPE': 'OTHER',
                'SRC': company_reports.loc[idx, 'SRC'] if idx < len(company_reports) else '',
                'REFYEAR': company_reports.loc[idx, 'REFYEAR'] if idx < len(company_reports) else ''
            })
    
    # Write to CSV
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['ID', 'NAME', 'TYPE', 'SRC', 'REFYEAR'])
        writer.writeheader()
        writer.writerows(results)
    
    print(f"Discovery CSV generated successfully: {output_file}")

def main():
    # Example usage
    input_file = "results/financial_reports.csv"
    template_file = "challenge/discovery-subset.csv"
    output_file = "discovery.csv"
    
    format_discovery_csv(input_file, template_file, output_file)

if __name__ == "__main__":
    main()
