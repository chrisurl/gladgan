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
- Improved handling of 202 HTTP responses with retries
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

Run the script with default parameters:

```
python run.py
```

This will process the companies listed in `challenge/discovery-subset.csv` and output the results to `discovery.csv`.

### Command Line Options

- `--input FILE`: Input CSV file path (default: 'challenge/discovery-subset.csv')
- `--output FILE`: Output discovery CSV file path (default: 'discovery.csv')
- `--batch-size INT`: Number of companies to process in batch (default: 5)

Example:

```
python run.py --input my_companies.csv --output my_discovery.csv --batch-size 10
```

## Structure

- `run.py`: Main script that orchestrates the entire process
- `company_report_finder.py`: Class for finding company reports
- `discovery_csv_generator.py`: Formats results according to challenge requirements
- `main_script.py`: Alternative entry point that includes submission packaging

## Approach

1. **Finding Investor Relations Pages**: The script searches for investor relations pages using DuckDuckGo, focusing on European domains.
2. **Extracting PDF Links**: It extracts PDF links from the pages and assigns relevance scores.
3. **Company-Specific Patterns**: For all companies in the list, it tries specific URL patterns.
4. **Year Extraction**: The reference year is extracted from the URL or link text.
5. **Format Conversion**: Results are formatted according to the challenge requirements.

## Improvements

### European Focus
- Filters out non-European domains (.gov, .us, etc.)
- Adds European-specific terms to search queries
- Implements specialized search strategies for each company

### Better Error Handling
- Handles 202 HTTP responses with intelligent retries
- Implements multiple attempts with different search strategies
- Gracefully handles timeouts and connection errors

### Enhanced PDF Discovery
- Supports direct PDF links
- Identifies download buttons and handles JavaScript-based downloads
- Uses company-specific pattern matching for all companies in the list
- Implements smart scoring to prioritize the most relevant reports

### More Robust Processing
- Processes companies individually for better error isolation
- Saves intermediate results after each company
- Implements pause mechanisms to avoid rate limiting
- Adds comprehensive logging for debugging

## Challenges and Solutions

- **Rate Limiting**: Implemented batch processing with pauses to avoid rate limiting.
- **Diverse URL Patterns**: Used company-specific pattern matching for all companies.
- **Reference Year Extraction**: Used regex patterns to extract years from URLs and texts.
- **Company Name Variations**: Implemented name normalization to handle company name variations.
- **HTTP 202 Responses**: Added intelligent retry mechanism for "accepted but processing" responses.
- **Non-European Results**: Filtered out non-European domains and added Europe-specific search terms.

## Future Improvements

- Add more company-specific patterns for direct PDF links
- Implement PDF content validation to ensure correct reports
- Add support for additional languages (German, French, Spanish, etc.)
- Implement distributed processing to handle larger company lists

## License

This project is licensed under the MIT License - see the LICENSE file for details.
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

Run the script with default parameters:

```
python run.py
```

This will process the companies listed in `challenge/discovery-subset.csv` and output the results to `discovery.csv`.

### Command Line Options

- `--input FILE`: Input CSV file path (default: 'challenge/discovery-subset.csv')
- `--output FILE`: Output discovery CSV file path (default: 'discovery.csv')
- `--batch-size INT`: Number of companies to process in batch (default: 5)

Example:

```
python run.py --input my_companies.csv --output my_discovery.csv --batch-size 10
```

## Structure

- `run.py`: Main script that orchestrates the entire process
- `company_report_finder.py`: Class for finding company reports
- `discovery_csv_generator.py`: Formats results according to challenge requirements
- `main_script.py`: Alternative entry point that includes submission packaging

## Approach

1. **Finding Investor Relations Pages**: The script searches for investor relations pages using DuckDuckGo.
2. **Extracting PDF Links**: It extracts PDF links from the pages and assigns relevance scores.
3. **Company-Specific Patterns**: For known companies, it tries specific URL patterns.
4. **Year Extraction**: The reference year is extracted from the URL or link text.
5. **Format Conversion**: Results are formatted according to the challenge requirements.

## Challenges and Solutions

- **Rate Limiting**: Implemented batch processing with pauses to avoid rate limiting.
- **Diverse URL Patterns**: Used company-specific pattern matching for major companies.
- **Reference Year Extraction**: Used regex patterns to extract years from URLs and texts.
- **Company Name Variations**: Implemented name normalization to handle company name variations.

## Future Improvements

- Add more company-specific patterns for direct PDF links
- Implement more robust error handling and retries
- Add support for additional languages
- Improve PDF content validation

## License

This project is licensed under the MIT License - see the LICENSE file for details.
