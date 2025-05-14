# config_handler.py
import json
import os
import sys

CONFIG_FILE = 'config.json'

def create_default_config():
    """Create a default config.json template file"""
    default_config = {
        "api_credentials": {
            "google_api_key": "YOUR_API_KEY_HERE",
            "google_search_engine_id": "YOUR_SEARCH_ENGINE_ID_HERE"
        },
        "settings": {
            "daily_api_limit": 100,
            "max_results_per_query": 10,
            "default_output_file": "results.json"
        }
    }
    
    try:
        with open(CONFIG_FILE, 'w') as f:
            json.dump(default_config, f, indent=4)
        
        print(f"Created template configuration file: {CONFIG_FILE}")
        print("Please edit this file to add your API credentials.")
        return default_config
    except Exception as e:
        print(f"Error creating configuration file: {e}")
        return None

def load_config():
    """Load configuration from config.json file"""
    if not os.path.exists(CONFIG_FILE):
        print(f"Configuration file {CONFIG_FILE} not found.")
        return create_default_config()
    
    try:
        with open(CONFIG_FILE, 'r') as f:
            config = json.load(f)
        
        # Check if API credentials are set
        credentials = config.get('api_credentials', {})
        api_key = credentials.get('google_api_key')
        engine_id = credentials.get('google_search_engine_id')
        
        if (api_key == "YOUR_API_KEY_HERE" or 
            engine_id == "YOUR_SEARCH_ENGINE_ID_HERE"):
            print("Warning: Default API credentials detected in config.json")
            print("Please edit the file to add your actual API credentials.")
        
        return config
    except json.JSONDecodeError:
        print(f"Error: {CONFIG_FILE} is not valid JSON.")
        create_default_config()
        sys.exit(1)
    except Exception as e:
        print(f"Error loading configuration: {e}")
        return None

def get_api_credentials(args):
    """Get API credentials from config or command line arguments"""
    config = load_config()
    
    # Priority: command line args > environment variables > config file
    api_key = (args.api_key or 
               os.environ.get('GOOGLE_API_KEY') or 
               config.get('api_credentials', {}).get('google_api_key'))
    
    search_engine_id = (args.search_engine_id or 
                         os.environ.get('GOOGLE_SEARCH_ENGINE_ID') or 
                         config.get('api_credentials', {}).get('google_search_engine_id'))
    
    # Check if we have valid credentials
    if (not api_key or 
        not search_engine_id or 
        api_key == "YOUR_API_KEY_HERE" or 
        search_engine_id == "YOUR_SEARCH_ENGINE_ID_HERE"):
        return None, None
    
    return api_key, search_engine_id

def get_setting(setting_name, args_value=None, default=None):
    """Get a setting from config file with optional override from args"""
    config = load_config()
    
    # Command line args override config settings
    if args_value is not None:
        return args_value
    
    # Get from config or use default
    return config.get('settings', {}).get(setting_name, default)