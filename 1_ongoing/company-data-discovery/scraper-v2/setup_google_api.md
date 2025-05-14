# Setting up Google Custom Search API

To use this tool, you need to set up a Google Custom Search Engine and get an API key.

## Step 1: Create a Google API Key

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or select an existing one)
3. Navigate to "APIs & Services" > "Library"
4. Search for "Custom Search API" and enable it
5. Go to "Credentials" and create an API key

## Step 2: Create a Custom Search Engine

1. Go to the [Custom Search Engine page](https://cse.google.com/cse/all)
2. Click "Add" to create a new search engine
3. Enter a name and select "Search the entire web"
4. Click "Create"
5. Go to "Setup" and get your Search Engine ID (cx value)

## Step 3: Configure the application

Set your API Key and Search Engine ID in the config file

1. Initialize the config file:
```bash 
python annual_report_finder.py --init-config
```

2. Edit the `config.json` file with your API credentials:
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

## Usage Limits

The free tier of Google Custom Search JSON API allows 100 search queries per day.