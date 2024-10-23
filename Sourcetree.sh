import requests
from bs4 import BeautifulSoup
import csv
import os

# Token Telegram dan chat ID langsung di-hardcode
telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"
chat_id = "-4523501737"  # Ganti dengan chat ID yang sesuai

# Fungsi untuk mendapatkan versi terbaru Sourcetree dari halaman download archives
def check_latest_version_sourcetree():
    url = "https://www.sourcetreeapp.com/download-archives"
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Cari elemen <a> yang berisi nomor versi terbaru menggunakan 'string'
        version_tag = soup.find('a', href=True, string=lambda x: x and x.replace('.', '').isdigit())
        
        if version_tag:
            latest_version = version_tag.string.strip()  # Mengambil nomor versi dari teks
            #print(f"Raw version string: '{version_tag.string.strip()}'")
            #print(f"Latest Sourcetree version found: {latest_version}")
            return latest_version
        else:
            print("Could not find the latest version information on the page.")
            return None

    else:
        print(f"Failed to access Sourcetree page. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["Sourcetree", "0.0.0", ""])  # Nilai default jika belum ada data
    
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
        #print(f"Telegram response status code: {response.status_code}")
        #print(f"Telegram response text: {response.text}")
        
        if response.status_code != 200:
            raise ValueError(f"Error {response.status_code}, response: {response.text}")
    except Exception as e:
        print(f"Error sending notification to Telegram: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    versions = read_current_version_csv()
    
    latest_sourcetree_version = check_latest_version_sourcetree()
    sourcetree_mungki_version, sourcetree_web_version = versions.get('Sourcetree', (None, None))

    if compare_versions(sourcetree_mungki_version, latest_sourcetree_version):
        print(f"New version of Sourcetree available: {latest_sourcetree_version}")
        
        update_web_version_csv("Sourcetree", latest_sourcetree_version)
        
        send_notification_telegram("Sourcetree", sourcetree_mungki_version, latest_sourcetree_version)
    else:
        print("Versi Sourcetree sudah yang terbaru.")

if __name__ == "__main__":
    main()
