import re
import requests
from bs4 import BeautifulSoup
import csv
import os

# Token Telegram dan chat ID langsung di-hardcode
telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"
chat_id = "-4523501737"  # Ganti dengan chat ID yang sesuai

# Fungsi untuk mendapatkan versi terbaru Skype dari halaman dukungan
def check_latest_version_skype():
    url = "https://support.microsoft.com/en-us/skype/what-s-new-in-skype-for-windows-mac-linux-and-web-d32f674c-abb3-40a5-a0b7-ee269ca60831"
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')

        # Mencari elemen yang mengandung informasi versi
        version_info = soup.find('h2')  # Mengambil elemen <h2> pertama
        if version_info:
            # Cari teks yang berisi versi
            text = version_info.find_next('p').text
            match = re.search(r'Skype for Windows, Mac, Linux, and Web (\d+\.\d+\.\d+\.\d+)', text)

            if match:
                latest_version = match.group(1)
                #print(f"Latest Skype version for Mac found: {latest_version}")
                return latest_version

        print("Could not find the latest version information for Mac.")
        return None

    else:
        print(f"Failed to access Skype page. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["Skype", "0.0.0", ""])  # Nilai default jika belum ada data
    
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
       # print(f"Telegram response status code: {response.status_code}")
        #print(f"Telegram response text: {response.text}")
        
        if response.status_code != 200:
            raise ValueError(f"Error {response.status_code}, response: {response.text}")
    except Exception as e:
        print(f"Error sending notification to Telegram: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    versions = read_current_version_csv()
    
    latest_skype_version = check_latest_version_skype()
    skype_mungki_version, skype_web_version = versions.get('Skype', (None, None))

    if latest_skype_version and compare_versions(skype_mungki_version, latest_skype_version):
        print(f"New version of Skype available: {latest_skype_version}")
        
        update_web_version_csv("Skype", latest_skype_version)
        
        send_notification_telegram("Skype", skype_mungki_version, latest_skype_version)
    else:
        print("Skype is up to date or could not retrieve the latest version.")

if __name__ == "__main__":
    main()
