# Scraper V2: Using Google

## Versioning with Poetry
To be filled. Most important: instead of `python <file>`, the user needs to execute `poetry run python3 <file>`.

## How to use

### Initialize the config file:
```bash 
python annual_report_finder.py --init-config
```

### Edit the `config.json` file with your API credentials:
```bash
json{
    "api_credentials": {
        "google_api_key": "your_actual_api_key_here",
        "google_search_engine_id": "your_actual_search_engine_id_here"
    },
    "settings": {
        "daily_api_limit": 100,
        "max_results_per_query": 10,
        "default_output_file": "results.json"
    }
}
```

### Run the script (no need to provide API credentials each time):

```bash
# Check remaining quota
python annual_report_finder.py --dry-run

# Process companies
python annual_report_finder.py --companies "ENI S P A" "VODAFONE GROUP PLC"
```

### Convert results to CSV if needed:

```bash
python results_to_csv.py results.json
```

## Key Features of This Implementation:

*  One-time setup with config.json - no need to enter API credentials repeatedly
*  Command line arguments can still override the config settings when needed
*  All settings can be managed in one place
*  Easy initialization with --init-config
*  Support for checking quota with --dry-run
*  Optional conversion to CSV format
*  Handles API usage tracking automatically