# api_tracker.py
import os
import csv
import datetime
from config_handler import get_setting

class APITracker:
    def __init__(self, tracker_file=None):
        self.tracker_file = tracker_file or 'google_api_usage.csv'
        self.today = datetime.datetime.now().strftime('%Y-%m-%d')
        self.usage_count = 0
        self._load_usage()
    
    def _load_usage(self):
        """Load current usage for today"""
        if not os.path.exists(self.tracker_file):
            # Create the file with headers if it doesn't exist
            with open(self.tracker_file, 'w', newline='') as f:
                writer = csv.writer(f)
                writer.writerow(['date', 'count'])
            return
        
        # Load the current count for today
        with open(self.tracker_file, 'r') as f:
            reader = csv.reader(f)
            next(reader)  # Skip header
            for row in reader:
                if row and row[0] == self.today:
                    self.usage_count = int(row[1])
                    break
    
    def can_make_request(self, daily_limit=None):
        """Check if we can make another request today"""
        if daily_limit is None:
            daily_limit = get_setting('daily_api_limit', None, 100)
        return self.usage_count < daily_limit
    
    def log_request(self):
        """Log a request and update the tracker file"""
        self.usage_count += 1
        
        # Read existing data
        rows = []
        today_updated = False
        
        if os.path.exists(self.tracker_file):
            with open(self.tracker_file, 'r') as f:
                reader = csv.reader(f)
                header = next(reader)
                rows.append(header)
                
                for row in reader:
                    if row and row[0] == self.today:
                        rows.append([self.today, self.usage_count])
                        today_updated = True
                    elif row:
                        rows.append(row)
        
        # Add today's entry if not updated
        if not today_updated:
            rows.append([self.today, self.usage_count])
        
        # Write back to file
        with open(self.tracker_file, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerows(rows)
        
        return self.usage_count
    
    def get_remaining_quota(self, daily_limit=None):
        """Get remaining API quota for today"""
        if daily_limit is None:
            daily_limit = get_setting('daily_api_limit', None, 100)
        return daily_limit - self.usage_count