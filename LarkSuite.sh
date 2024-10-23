import requests
from bs4 import BeautifulSoup
import csv
import os
import re

# Token Telegram dan chat ID
telegram_token = "YOUR_TELEGRAM_BOT_TOKEN"  # Replace with your Telegram bot token
chat_id = "YOUR_CHAT_ID"  # Replace with your chat ID

# URL for Lark Suite updates
url = "https://www.larksuite.com/hc/en-US/category/7054521562770210822-version-updates"

# Function to get the latest version of Lark Suite using requests and BeautifulSoup
def check_latest_version_lark():
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')

        # Search for the div with the class "hc_menuitem_content"
        version_divs = soup.find_all('div', class_="hc_menuitem_content")

        for div in version_divs:
            text = div.get_text(strip=True)
            # Match the version pattern in the text (e.g., V7.27)
            version_match = re.search(r'V(\d+\.\d+)', text)

            if version_match:
                version = version_match.group(1)  # Get only the version number
                return version  # Return the version in the format '7.27'

        print("Could not find the version information in the page.")
        return None

    else:
        print(f"Failed to access Lark Suite page. Status code: {response.status_code}")
        return None

# Function to read the current version from the CSV file
def read_current_version_csv():
    filename = 'current_version.csv'

    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["Lark Suite", "0.0.0", ""])  # Default value if no data exists yet

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

    latest_lark_version = check_latest_version_lark()
    lark_mungki_version, lark_web_version = versions.get('Lark Suite', (None, None))

    if latest_lark_version and compare_versions(lark_mungki_version, latest_lark_version):
        print(f"New version of Lark Suite available: {latest_lark_version}")

        update_web_version_csv("Lark Suite", latest_lark_version)

        send_notification_telegram("Lark Suite", lark_mungki_version, latest_lark_version)
    else:
        print("Lark Suite is up to date or could not retrieve the latest version.")

if __name__ == "__main__":
    main()
