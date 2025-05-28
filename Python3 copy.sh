import requests
from bs4 import BeautifulSoup
import csv
import os
import re
import json

# URL Webhook Lark
lark_webhook_url = "https://open.larksuite.com/open-apis/bot/v2/hook/f5a3af1a-bd6a-4482-bf93-fdf9b58bfab6"

# Fungsi untuk mendapatkan versi terbaru Python dari halaman rilis resmi
def check_latest_version_python():
    url = "https://www.python.org/downloads/"
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')
        version_tag = soup.find('a', href=re.compile(r'python-(\d+\.\d+\.\d+)-macos'))
        if version_tag:
            version_match = re.search(r'python-(\d+\.\d+\.\d+)', version_tag['href'])
            if version_match:
                return version_match.group(1)
        print("Could not find the latest version information for Python.")
        return None
    else:
        print(f"Failed to access Python website. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["Python", "0.0.0", ""])
    
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        versions = {row['Software']: (row['Munki Version'], row['Web Version']) for row in reader}
    
    return versions

# Fungsi untuk memperbarui Web Version di file CSV
def update_web_version_csv(software_name, new_version):
    filename = 'current_version.csv'
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

# Fungsi untuk membandingkan versi
def compare_versions(Munki_version, latest_version):
    return Munki_version != latest_version

# Fungsi untuk mengirim notifikasi ke Lark
def send_notification_lark(software_name, Munki_version, latest_version):
    message = (
        f"**Update Available for {software_name}!**\n"
        f"Munki Version: `{Munki_version}`\n"
        f"Latest Version: `{latest_version}`"
    )
    
    payload = {
        "msg_type": "text",
        "content": {
            "text": message
        }
    }

    headers = {
        "Content-Type": "application/json"
    }

    try:
        response = requests.post(lark_webhook_url, headers=headers, data=json.dumps(payload))
        if response.status_code != 200:
            print(f"Failed to send Lark message: {response.status_code}, {response.text}")
    except Exception as e:
        print(f"Error sending message to Lark: {e}")

# Fungsi utama
def main():
    versions = read_current_version_csv()
    
    latest_python_version = check_latest_version_python()
    python_Munki_version, _ = versions.get('Python', (None, None))

    if latest_python_version and compare_versions(python_Munki_version, latest_python_version):
        print(f"New version of Python3 available: {latest_python_version}")
        update_web_version_csv("Python", latest_python_version)
        send_notification_lark("Python", python_Munki_version, latest_python_version)
    else:
        print("Python3 is up to date or could not retrieve the latest version.")

if __name__ == "__main__":
    main()
