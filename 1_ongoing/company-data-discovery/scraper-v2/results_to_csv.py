# results_to_csv.py
import json
import csv
import argparse
import os

def convert_to_csv(json_file, csv_file=None):
    """Convert JSON results to CSV format"""
    if not os.path.exists(json_file):
        print(f"Error: JSON file {json_file} not found.")
        return False
    
    # Default CSV filename
    if csv_file is None:
        csv_file = os.path.splitext(json_file)[0] + '.csv'
    
    try:
        # Load JSON data
        with open(json_file, 'r') as f:
            data = json.load(f)
        
        # Prepare CSV data
        csv_rows = []
        
        for company, results in data.items():
            # Add first result as FIN_REP
            if results:
                first_result = results[0]
                csv_rows.append({
                    'NAME': company,
                    'TYPE': 'FIN_REP',
                    'SRC': first_result['url'],
                    'REFYEAR': first_result.get('year', '')
                })
                
                # Add remaining results as OTHER
                for i, result in enumerate(results[1:6], 1):  # Limit to 5 additional links
                    csv_rows.append({
                        'NAME': company,
                        'TYPE': 'OTHER',
                        'SRC': result['url'],
                        'REFYEAR': result.get('year', '')
                    })
            else:
                # Add empty row if no results
                csv_rows.append({
                    'NAME': company,
                    'TYPE': 'FIN_REP',
                    'SRC': '',
                    'REFYEAR': ''
                })
        
        # Write to CSV
        with open(csv_file, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=['NAME', 'TYPE', 'SRC', 'REFYEAR'], delimiter=";")
            writer.writeheader()
            writer.writerows(csv_rows)
        
        print(f"Results converted to CSV: {csv_file}")
        return True
    
    except Exception as e:
        print(f"Error converting to CSV: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Convert JSON results to CSV format')
    parser.add_argument('--json_file', help='Input JSON results file')
    parser.add_argument('--output', help='Output CSV file')
    
    args = parser.parse_args()
    convert_to_csv(args.json_file, args.output)

if __name__ == "__main__":
    main()