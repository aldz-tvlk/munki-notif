import requests
from bs4 import BeautifulSoup
import csv
import os
import re

# Telegram Bot Token and Chat ID
telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"
chat_id = "-4523501737"  # Chat ID untuk Telegram

# URL to get LastPass version from the Apple App Store page
url = "https://apps.apple.com/us/app/lastpass-password-manager/id926036361"

# Function to get the latest version of LastPass using requests and BeautifulSoup
def check_latest_version_lastpass():
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')

        # Find the version information in the page
        version_tag = soup.find('p', class_='l-column small-6 medium-12 whats-new__latest__version')
        if version_tag:
            version_match = re.search(r'Version macOS (\d+\.\d+\.\d+)', version_tag.text.strip())
            if version_match:
                return version_match.group(1)

        print("Could not find the version information in the page.")
        return None
    else:
        print(f"Failed to access LastPass page. Status code: {response.status_code}")
        return None

# Function to read the current version from the CSV file
def read_current_version_csv():
    filename = 'current_version.csv'

    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["LastPass", "0.0.0", ""])  # Default value if no data exists yet

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
                        f"New version: {latest_version}")

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

    latest_lastpass_version = check_latest_version_lastpass()
    lastpass_mungki_version, lastpass_web_version = versions.get('LastPass', (None, None))

    if latest_lastpass_version and compare_versions(lastpass_mungki_version, latest_lastpass_version):
        print(f"New version of LastPass available: {latest_lastpass_version}")

        update_web_version_csv("LastPass", latest_lastpass_version)

        send_notification_telegram("LastPass", lastpass_mungki_version, latest_lastpass_version)
    else:
        print("LastPass is up to date or could not retrieve the latest version.")

if __name__ == "__main__":
    main()
