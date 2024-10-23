import requests
from bs4 import BeautifulSoup
import csv
import os
import re

# Token Telegram dan chat ID
telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"
chat_id = "-4523501737"  # Ganti dengan chat ID yang sesuai

# Fungsi untuk mendapatkan versi terbaru Reactotron dari halaman resmi
def check_latest_version_reactotron():
    url = "https://github.com/infinitered/reactotron/releases?q=reactotron-app&expanded=true"
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')

        # Mencari elemen yang mengandung informasi versi
        version_tag = soup.find('a', href=re.compile(r'/infinitered/reactotron/releases/tag/reactotron-app%40\d+\.\d+\.\d+'))
        if version_tag:
            # Menggunakan regex untuk mengekstrak versi dalam format yang benar
            version_match = re.search(r'\d+\.\d+\.\d+', version_tag.text.strip())
            if version_match:
                latest_version = version_match.group(0)  # Mengambil versi yang cocok
                #print(f"Latest Reactotron version found: {latest_version}")
                return latest_version

        print("Could not find the latest version information for Reactotron.")
        return None

    else:
        print(f"Failed to access Reactotron page. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["Reactotron", "0.0.0", ""])  # Nilai default jika belum ada data
    
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        versions = {row['Software']: (row['Mungki Version'], row['Web Version']) for row in reader}
    
    return versions

# Fungsi untuk memperbarui kolom Web Version di file CSV
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

# Fungsi untuk membandingkan versi
def compare_versions(mungki_version, latest_version):
    return mungki_version != latest_version

# Fungsi untuk mengirim notifikasi ke Telegram
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

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    versions = read_current_version_csv()
    
    latest_reactotron_version = check_latest_version_reactotron()
    reactotron_mungki_version, reactotron_web_version = versions.get('Reactotron', (None, None))

    if latest_reactotron_version and compare_versions(reactotron_mungki_version, latest_reactotron_version):
        print(f"New version of Reactotron available: {latest_reactotron_version}")
        
        update_web_version_csv("Reactotron", latest_reactotron_version)
        
        send_notification_telegram("Reactotron", reactotron_mungki_version, latest_reactotron_version)
    else:
        print("Versi Reactotron sudah yang terbaru.")

if __name__ == "__main__":
    main()
