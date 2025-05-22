# Scraper V2: Using Google

## Setup google API
See `setup_google_api.md`.

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
        "daily_api_limit": 1000,
        "max_results_per_query": 10,
        "default_output_file": "results.json"
    }
}
```
For the rate limit, make sure to select a suiting limit. In our case, google provided some extra credits as a starting gift. Therefore, we can be a bit more generous with the daily limits without having any costs.

### Run the script (no need to provide API credentials each time):

```bash
# Check remaining quota
python annual_report_finder.py --dry-run

# Process companies by name
python annual_report_finder.py --companies "ENI S P A" "VODAFONE GROUP PLC"

# Process companies from file
python annual_report_finder.py --input-file ../challenge/discovery-clean.csv --output first-run.json   
```

### Convert results to CSV if needed:

```bash
python results_to_csv.py --json_file ../results/first-run.json --output ../results/first-run.csv
python results_to_csv_with_id.py --results_file ../results/first-run.csv --discovery_file ../challenge/discovery.csv --output ../results/first-run-final.csv
python empty_invalid_refyear.py --input ../results/first-run-final.csv --output ../results/first-run-clean.csv
```

## Key Features of This Implementation:

*  One-time setup with config.json - no need to enter API credentials repeatedly
*  Command line arguments can still override the config settings when needed
*  All settings can be managed in one place
*  Easy initialization with --init-config
*  Support for checking quota with --dry-run
*  Optional conversion to CSV format
*  Handles API usage tracking automatically

## Poetry

If you intend to use poetry and the `poetry.lock`, `pyproject.toml`files, the above python commands translate to:

```bash
poetry run python annual_report_finder.py --input-file ../challenge/discovery-clean.csv --output first-run.json
poetry run python results_to_csv.py --json_file ../results/first-run.json --output ../results/first-run.csv
```

If you are on MacOS and face the same difficulties as I did, please use `python3` instead of `python`.

If you don´t know poetry, here is a short intro.

## Poetry Setup

This project uses Poetry for dependency management and virtual environment handling. Poetry is a modern dependency management tool for Python that simplifies package installation and virtual environment management.

### Installing Poetry

If you don't have Poetry installed, you can install it using:

```bash
# On macOS/Linux/WSL
curl -sSL https://install.python-poetry.org | python3 -

# On Windows (PowerShell)
(Invoke-WebRequest -Uri https://install.python-poetry.org -UseBasicParsing).Content | py -
```

### Installing Dependencies

Once Poetry is installed, navigate to the project directory and run:

```bash
poetry install
```

This will automatically create a virtual environment and install all required dependencies specified in the `pyproject.toml` file.

### Activating the Environment

To activate the Poetry virtual environment:

```bash
poetry shell
```

Alternatively, you can run commands directly in the Poetry environment without activating it:

```bash
poetry run python your_script.py
```
