import requests
from bs4 import BeautifulSoup
import csv
import os
import re
import subprocess

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
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["iTerm2", "0.0.0", ""])  # Default value if no data exists yet

    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        versions = {row['Software']: (row['Munki Version'], row['Web Version']) for row in reader}

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
        writer = csv.DictWriter(file, fieldnames=["Software", "Munki Version", "Web Version"])
        writer.writeheader()
        writer.writerows(rows)

# Fungsi untuk memperbarui kolom Munki Version di file CSV
def update_munki_version_csv(software_name, new_version):
    filename = 'current_version.csv'
    rows = []
    # Baca semua baris dari CSV
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        rows = list(reader)
    
    # Update versi Munki Version pada baris yang sesuai
    for row in rows:
        if row['Software'] == software_name:
            row['Munki Version'] = new_version
    
    # Tulis kembali file CSV dengan pembaruan
    with open(filename, 'w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=["Software", "Munki Version", "Web Version"])
        writer.writeheader()
        writer.writerows(rows)

# Function to compare versions
def compare_versions(Munki_version, latest_version):
    return Munki_version != latest_version

# Jalankan autopkg untuk download dan import ke Munki
def run_autopkg():
    success = True
    failed_archs = []

    try:
        # Jalankan untuk Apple Silicon (arm64)
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.iTerm2"], check=True)
        print("Autopkg berhasil dijalankan untuk MAC.")
    except subprocess.CalledProcessError:
        print("Autopkg gagal.")
        success = False
        failed_archs.append("Apple Silicon (arm64)")

    # Kirim notifikasi jika ada yang gagal
    if not success:
        failed_msg = "\n".join(failed_archs)
        send_notification_telegram("iTerm2", "Failed Import", f"Autopkg gagal untuk:\n{failed_msg}")

    return success

# Function to send a notification to Telegram
def send_notification_telegram(software_name, Munki_version, latest_version):
    telegram_message = (f"Update Available for {software_name}!\n"
                        f"Munki Version: {Munki_version}\n"
                        f"Latest version: {latest_version}\n"
                        f"iTerm2 is Already Import to MunkiAdmin")

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
    iterm2_Munki_version, iterm2_web_version = versions.get('iTerm2', (None, None))

    if latest_iterm2_version and compare_versions(iterm2_Munki_version, latest_iterm2_version):
        print(f"Version baru iTerm2 tersedia: {latest_iterm2_version}")
        update_web_version_csv("iTerm2", latest_iterm2_version)
        # Jalankan autopkg
        run_autopkg()
        # Perbarui kolom Munki Version di file CSV
        update_munki_version_csv("iTerm2", latest_iterm2_version)
        send_notification_telegram("iTerm2", iterm2_Munki_version, latest_iterm2_version)
    else:
        print("Version iTerm2 sudah yang terbaru.")

if __name__ == "__main__":
    main()