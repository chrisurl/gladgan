import pandas as pd

def empty_invalid_refyear_rows(csv_file_path, output_file_path=None):
    """
    Empty out rows where REFYEAR is not in range 2018-2025
    
    Args:
        csv_file_path: Path to the CSV file with REFYEAR column
        output_file_path: Path for output file (if None, overwrites input file)
    """
    if output_file_path is None:
        output_file_path = csv_file_path
    
    # Read the CSV file
    df = pd.read_csv(csv_file_path, delimiter=";", dtype={'REFYEAR': 'str'})
    
    print(f"Original data shape: {df.shape}")
    print(f"Original REFYEAR values: {df['REFYEAR'].value_counts()}")
    
    # Define valid years
    valid_years = ['2018', '2019', '2020', '2021', '2022', '2023', '2024', '2025']
    
    # Find rows with invalid REFYEAR (not in valid range and not empty)
    invalid_mask = (
        (df['REFYEAR'].notna()) & 
        (df['REFYEAR'] != '') & 
        (~df['REFYEAR'].astype(str).isin(valid_years))
    )
    
    invalid_count = invalid_mask.sum()
    print(f"\nFound {invalid_count} rows with invalid REFYEAR values")
    
    if invalid_count > 0:
        print("Invalid REFYEAR values found:")
        print(df[invalid_mask]['REFYEAR'].value_counts())
        
        # Empty out SRC and REFYEAR for invalid rows, keep ID, NAME, TYPE
        df.loc[invalid_mask, 'SRC'] = ''
        df.loc[invalid_mask, 'REFYEAR'] = ''
        
        print(f"\nEmptied SRC and REFYEAR for {invalid_count} rows with invalid years")
    
    # Show final REFYEAR distribution
    print(f"\nFinal REFYEAR values: {df['REFYEAR'].value_counts()}")
    
    # Verify no invalid years remain
    remaining_invalid = df[
        (df['REFYEAR'].notna()) & 
        (df['REFYEAR'] != '') & 
        (~df['REFYEAR'].astype(str).isin(valid_years))
    ]
    
    if remaining_invalid.empty:
        print("✓ All REFYEAR values are now valid or empty")
    else:
        print(f"⚠ Warning: {len(remaining_invalid)} rows still have invalid REFYEAR values")
    
    # Save the cleaned data
    df.to_csv(output_file_path, index=False, quoting=1, sep=";")
    print(f"\nCleaned data saved to: {output_file_path}")
    
    return df

# Example usage
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Empty rows with invalid REFYEAR values')
    parser.add_argument('--input', required=True, help='Input CSV file')
    parser.add_argument('--output', help='Output CSV file (optional, overwrites input if not specified)')
    
    args = parser.parse_args()
    
    empty_invalid_refyear_rows(args.input, args.output)
