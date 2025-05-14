# Financial Reports Discovery

This project automates the discovery of financial reports for multinational enterprises (MNEs), as part of the data discovery challenge.

## Overview

The solution finds financial reports for companies listed in a CSV file and formats the results according to the challenge requirements. It uses web scraping and search techniques to find direct links to annual financial reports and extract the reference year.

## Features

- Automatically finds investor relations pages and annual report PDFs
- Extracts the reference year from PDF links or descriptions
- Uses intelligent scoring to prioritize the most relevant reports
- Handles company name variations and normalizes search queries
- Processes companies in batches with pauses to avoid IP blocks
- Creates properly formatted discovery.csv file
- European company focus with filtering of non-European domains
- Rate limit handling with one-hour waits when needed
- Company-specific pattern matching for all companies in the list

## Requirements

- Python 3.6 or higher
- Required packages:
  - requests
  - beautifulsoup4
  - pandas
  - urllib3

## Installation

1. Clone the repository:

```
git clone https://github.com/your-username/financial-reports-discovery.git
cd financial-reports-discovery
```

2. Install the required packages:

```
pip install -r requirements.txt
```

## Usage

### Full Processing

Run the script with default parameters:

```
python fixed_main_script.py
```

This will process the companies listed in `challenge/discovery-subset.csv` and output the results to `discovery.csv`.

### Command Line Options

- `--input FILE`: Input CSV file path (default: 'challenge/discovery-subset.csv')
- `--output FILE`: Output discovery CSV file path (default: 'discovery.csv')
- `--batch-size INT`: Number of companies to process in batch (default: 5)
- `--single-company NAME`: Process only a single company by name for testing

Example:

```
python fixed_main_script.py --input my_companies.csv --output my_discovery.csv --batch-size 10
```

### Testing with a Single Company

For testing and debugging, you can use either the main script with the `--single-company` option:

```
python fixed_main_script.py --single-company "Siemens"
```

Or you can use the dedicated test script:

```
python test_company.py "Siemens"
```

## Rate Limit Handling

The script includes enhanced handling for DuckDuckGo rate limits:

1. When a 202 status code is detected (indicating rate limiting), the script will:
   - First try short retries (10 seconds apart)
   - If that fails, wait for 1 hour before retrying
   - If rate limiting persists, the script will wait for another hour
   - After two one-hour waits, it will move on to the next company

2. Detailed logging is provided during the wait periods, including:
   - Current time and expected retry time
   - Countdown in minutes during the wait 
   - Status of each retry attempt

## Structure

- `company_report_finder_fixed.py`: Class for finding company reports
- `fixed_main_script.py`: Main script that orchestrates the entire process
- `test_company.py`: Test script for running a single company test

## Approach

1. **Finding Investor Relations Pages**: The script searches for investor relations pages using DuckDuckGo, focusing on European domains.
2. **Extracting PDF Links**: It extracts PDF links from the pages and assigns relevance scores.
3. **Company-Specific Patterns**: For all companies in the list, it tries specific URL patterns.
4. **Year Extraction**: The reference year is extracted from the URL or link text.
5. **Format Conversion**: Results are formatted according to the challenge requirements.

## Future Improvements

- Add more company-specific patterns for direct PDF links
- Implement more robust error handling and retries
- Add support for additional languages
- Improve PDF content validation

## License

This project is licensed under the MIT License - see the LICENSE file for details.
