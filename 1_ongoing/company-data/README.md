# Company data retrieval

## Current state of affairs

*   Created `import requests.py` which is a first try. Problem: for siemens we check the website https://www.siemens.com/global/en/company/investor-relations/events-publications-ad-hoc/annualreports.html and there, we can find the download button which leads to https://www.siemens.com/applications/b09c49eb-3a14-73b3-9f71-e30e3c2dfdbd/assets/pdfs/en/Siemens_Report_FY2024.pdf and donwloads the pdfs. 

Long story short: we will need to re-fine the webscraper in order to retrieve the correct links to the reports.

*   another way would be to start off the exercise manually for the first 20 reports and then see if we could replicate this approach using duckduckgo and claude. 