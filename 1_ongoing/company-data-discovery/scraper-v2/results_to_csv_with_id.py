import pandas as pd
import os
import argparse

def add_id_to_results(results_csv_path, discovery_csv_path, output_csv_path):
    """
    Add ID column to results by joining with discovery.csv
    
    Args:
        results_csv_path: Path to the results CSV file
        discovery_csv_path: Path to the discovery.csv file containing ID-NAME mapping
        output_csv_path: Path for the output CSV file
    """
    # Read the results file
    if not os.path.exists(results_csv_path):
        print(f"Error: Results file {results_csv_path} not found")
        return
        
    # Read the discovery file for ID mapping
    if not os.path.exists(discovery_csv_path):
        print(f"Error: Discovery file {discovery_csv_path} not found")
        return
    
    # Load data
    results_df = pd.read_csv(results_csv_path, delimiter=";",dtype={'REFYEAR': 'str'})
    discovery_df = pd.read_csv(discovery_csv_path, delimiter=";", dtype={'REFYEAR': 'str'})
    
    # Get unique ID-NAME mapping from discovery.csv
    id_mapping = discovery_df[['ID', 'NAME']].drop_duplicates()
    
    print(f"Loaded {len(results_df)} results and {len(id_mapping)} unique ID-NAME mappings")
    
    # Join results with ID mapping
    # Left join to keep all results, even if no ID found
    results_with_id = results_df.merge(id_mapping, on='NAME', how='left')
    
    # Reorder columns to put ID first
    columns = ['ID'] + [col for col in results_with_id.columns if col != 'ID']
    results_with_id = results_with_id[columns]
    
    # Check for any missing IDs
    missing_ids = results_with_id[results_with_id['ID'].isna()]
    if not missing_ids.empty:
        print(f"Warning: {len(missing_ids)} rows have missing IDs:")
        print(missing_ids['NAME'].unique())
    
    # Save the updated results
    results_with_id.to_csv(output_csv_path, index=False, sep=";")
    print(f"Updated results saved to {output_csv_path}")
    print(f"Final dataset has {len(results_with_id)} rows with columns: {list(results_with_id.columns)}")
    
    return results_with_id

def main():
    """Main function to process the results file"""
    
    parser = argparse.ArgumentParser(description='Add ID column to results CSV by joining with discovery.csv')
    parser.add_argument('--results_file', help='Input results CSV file', default='results/financial_reports.csv')
    parser.add_argument('--discovery_file', help='Discovery CSV file with ID-NAME mapping', default='challenge/discovery.csv')
    parser.add_argument('--output', help='Output CSV file', default='results/financial_reports_with_id.csv')
    
    args = parser.parse_args()
    
    # Use provided arguments or fall back to defaults
    results_file = args.results_file
    discovery_file = args.discovery_file
    output_file = args.output
    
    # Check if files exist, try alternatives if defaults don't exist
    if not os.path.exists(results_file) and args.results_file == 'results/financial_reports.csv':
        # Try alternative path if using default
        if os.path.exists("financial_reports.csv"):
            results_file = "financial_reports.csv"
    
    if not os.path.exists(discovery_file) and args.discovery_file == 'challenge/discovery.csv':
        # Try alternative paths if using default
        for alt_path in ["discovery.csv", "challenge/discovery-subset.csv"]:
            if os.path.exists(alt_path):
                discovery_file = alt_path
                break
    
    print(f"Processing:")
    print(f"  Results file: {results_file}")
    print(f"  Discovery file: {discovery_file}")
    print(f"  Output file: {output_file}")
    
    # Process the files
    updated_df = add_id_to_results(results_file, discovery_file, output_file)
    
    if updated_df is not None:
        print("\nSample of updated data:")
        print(updated_df.head())

if __name__ == "__main__":
    main()
