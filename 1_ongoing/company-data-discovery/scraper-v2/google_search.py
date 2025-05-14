# google_search.py
import requests
import json
import os
from api_tracker import APITracker
from config_handler import get_setting

class GoogleSearchAPI:
    def __init__(self, api_key, search_engine_id, daily_limit=None):
        self.api_key = api_key
        self.search_engine_id = search_engine_id
        
        if not self.api_key or not self.search_engine_id:
            raise ValueError("Google API key and Search Engine ID are required.")
        
        self.tracker = APITracker()
        self.daily_limit = daily_limit or get_setting('daily_api_limit', None, 100)
    
    def search(self, query, num_results=10):
        """Perform a Google search using the Custom Search JSON API"""
        if not self.tracker.can_make_request(self.daily_limit):
            print(f"Daily API limit reached ({self.daily_limit} requests). Try again tomorrow.")
            return []
        
        base_url = "https://www.googleapis.com/customsearch/v1"
        
        params = {
            'key': self.api_key,
            'cx': self.search_engine_id,
            'q': query,
            'num': min(num_results, 10)  # API limit is 10 results per query
        }
        
        try:
            response = requests.get(base_url, params=params)
            self.tracker.log_request()
            
            if response.status_code != 200:
                print(f"API Error: {response.status_code}")
                print(response.text)
                return []
            
            data = response.json()
            
            results = []
            if 'items' in data:
                for item in data['items']:
                    results.append({
                        'title': item.get('title', ''),
                        'url': item.get('link', ''),
                        'snippet': item.get('snippet', '')
                    })
            
            # Print remaining quota
            remaining = self.tracker.get_remaining_quota(self.daily_limit)
            print(f"Remaining API quota for today: {remaining}")
            
            return results
        
        except Exception as e:
            print(f"Search error: {e}")
            return []

def search_google(company_name, num_results=10, api_key=None, search_engine_id=None):
    """Search for company annual reports using Google API"""
    query = f"{company_name} annual report"
    print(f"Searching for: {query}")
    
    try:
        google_api = GoogleSearchAPI(api_key, search_engine_id)
        results = google_api.search(query, num_results)
        
        # Extract just the URLs for backward compatibility
        return [result['url'] for result in results]
    
    except Exception as e:
        print(f"Search error: {e}")
        return []