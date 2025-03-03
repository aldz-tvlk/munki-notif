import requests
from bs4 import BeautifulSoup
import csv
import os
import re

# Telegram Bot Token and Chat ID
telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"
chat_id = "-4523501737"  # Chat ID untuk Telegram

# URL to check Chrome Stable Channel updates
url = "https://chromereleases.googleblog.com/search/label/Stable%20updates"

# Function to get the latest version of Chrome using requests and BeautifulSoup
def check_latest_version_chrome():
    response = requests.get(url)
    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')

        # Cari elemen post yang berisi 'Stable Channel Update for Desktop'
        posts = soup.find_all('div', class_='post')
        
        for post in posts:
            title_element = post.find('h2', class_='title')
            if title_element and "Stable Channel Update for Desktop" in title_element.get_text():
                # Temukan konten dalam post
                post_content = post.find('div', class_='post-body')
                if post_content:
                    version_text = post_content.get_text()
                    
                    # Gunakan regex untuk mencari versi Chrome
                    version_match = re.findall(r'(\d{2,3}\.\d+\.\d+\.\d+)', version_text)

                    if version_match:
                        # Ambil versi terbaru dari hasil pencarian
                        latest_version = version_match[-1]  # Biasanya versi terbaru ada di akhir
                        
                        # Cek apakah versi sesuai dengan yang dicari
                        if latest_version == latest_version:
                            #print(f"Version found: {latest_version}")  # Debugging output

                            return latest_version
                        else:
                            print(f"Found version: {latest_version}, but it's not the expected version.")
                    else:
                        print("Could not find version number in the text.")
                break  # Keluar dari loop jika sudah menemukan post
        
        print("Could not find 'Stable Channel Update for Desktop' post.")
        return None
    else:
        print(f"Failed to access Chrome update page. Status code: {response.status_code}")
        return None

# Function to read the current version from the CSV file
def read_current_version_csv():
    filename = 'current_version.csv'

    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["Google Chrome", "0.0.0", ""])  # Default value if no data exists yet

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

    latest_chrome_version = check_latest_version_chrome()
    chrome_mungki_version, chrome_web_version = versions.get('Google Chrome', (None, None))

    if latest_chrome_version and compare_versions(chrome_mungki_version, latest_chrome_version):
        print(f"New version of Google Chrome available: {latest_chrome_version}")

        update_web_version_csv("Google Chrome", latest_chrome_version)

        send_notification_telegram("Google Chrome", chrome_mungki_version, latest_chrome_version)
    else:
        print("Google Chrome is up to date or could not retrieve the latest version.")

if __name__ == "__main__":
    main()
