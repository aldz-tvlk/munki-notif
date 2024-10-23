import requests
from bs4 import BeautifulSoup
import csv
import os
import re

# Telegram Bot Token and Chat ID
telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"
chat_id = "-4523501737"  # Chat ID untuk Telegram

# URL to get iTerm2 release version
url = "https://iterm2.com/downloads.html"

# Function to get the latest version of iTerm2 using requests and BeautifulSoup
def check_latest_version_iterm2():
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')

        # Look for the first release information that contains the version number
        version_tag = soup.find('a', href=re.compile(r'iTerm2.*\.zip'))  # Looks for links to .zip files with version info

        if version_tag:
            # Extract version number from the text (e.g., iTerm2-3_4_18.zip -> 3.4.18)
            version_match = re.search(r'iTerm2-(\d+_\d+_\d+)\.zip', version_tag['href'])
            if version_match:
                version = version_match.group(1).replace('_', '.')  # Convert underscore to dots
                return version

        print("Could not find the version information in the page.")
        return None
    else:
        print(f"Failed to access iTerm2 page. Status code: {response.status_code}")
        return None

# Function to read the current version from the CSV file
def read_current_version_csv():
    filename = 'current_version.csv'

    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["iTerm2", "0.0.0", ""])  # Default value if no data exists yet

    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        versions = {row['Software']: (row['Mungki Version'], row['Web Version']) for row in reader}

    return versions

# Function to update the web version column in the CSV file
def update_web_version_csv(software_name, new_version):
    filename = 'current_version.csv'
    rows = []

    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        rows = list(reader)

    for row in rows:
        if row['Software'] == software_name:
            row['Web Version'] = new_version

    with open(filename, 'w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=["Software", "Mungki Version", "Web Version"])
        writer.writeheader()
        writer.writerows(rows)

# Function to compare versions
def compare_versions(mungki_version, latest_version):
    return mungki_version != latest_version

# Function to send a notification to Telegram
def send_notification_telegram(software_name, mungki_version, latest_version):
    telegram_message = (f"Update Available for {software_name}!\n"
                        f"Mungki Version: {mungki_version}\n"
                        f"Latest version: {latest_version}")

    send_text_url = f"https://api.telegram.org/bot{telegram_token}/sendMessage"
    params = {
        'chat_id': chat_id,
        'text': telegram_message,
        'parse_mode': 'Markdown'
    }

    try:
        response = requests.get(send_text_url, params=params)
        if response.status_code != 200:
            raise ValueError(f"Error {response.status_code}, response: {response.text}")
    except Exception as e:
        print(f"Error sending notification to Telegram: {e}")

# Main process to check the version and update if necessary
def main():
    versions = read_current_version_csv()

    latest_iterm2_version = check_latest_version_iterm2()
    iterm2_mungki_version, iterm2_web_version = versions.get('iTerm2', (None, None))

    if latest_iterm2_version and compare_versions(iterm2_mungki_version, latest_iterm2_version):
        print(f"New version of iTerm2 available: {latest_iterm2_version}")

        update_web_version_csv("iTerm2", latest_iterm2_version)

        send_notification_telegram("iTerm2", iterm2_mungki_version, latest_iterm2_version)
    else:
        print("iTerm2 is up to date or could not retrieve the latest version.")

if __name__ == "__main__":
    main()
