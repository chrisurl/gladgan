# result_ranker.py
from datetime import datetime

def rank_results(results):
    """Rank results based on year and link type"""
    current_year = datetime.now().year
    
    for result in results:
        score = 0
        
        # Prefer PDFs
        if result.get('is_pdf', False):
            score += 5
        
        # Score based on year
        year_str = result.get('year')
        if year_str and year_str.isdigit():
            year = int(year_str)
            if year == current_year:
                score += 10
            elif year == current_year - 1:
                score += 8
            elif year == current_year - 2:
                score += 6
            elif year >= current_year - 5:
                score += 4
            else:
                score += 2
        
        result['score'] = score
    
    # Sort by score (descending)
    return sorted(results, key=lambda x: x.get('score', 0), reverse=True)