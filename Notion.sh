import requests
import re
import os
import csv
from bs4 import BeautifulSoup

# Fungsi untuk mendapatkan versi terbaru Notion dari halaman release notes
def check_latest_version_notion():
    url = "https://www.notion.so/desktop"

    try:
        response = requests.get(url)
        response.raise_for_status()  # Pastikan responsnya sukses
        soup = BeautifulSoup(response.text, 'html.parser')

        # Cari elemen yang berisi informasi versi terbaru
        version_tag = soup.find('div', class_='version')  # Sesuaikan dengan class atau tag yang relevan
        if version_tag:
            latest_version = version_tag.text.strip()  # Mengambil teks dan menghapus spasi
            return latest_version
        else:
            print("No version information found for Notion.")
            return None
    except Exception as e:
        print(f"Error fetching version information for Notion: {e}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["Notion", "None", ""])  # Ganti dengan versi yang sesuai jika perlu
    
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        versions = {}
        for row in reader:
            versions[row['Software']] = (row['Mungki Version'], row['Web Version'])
    
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
def compare_versions(mungki_version, web_version):
    return mungki_version != web_version

# Fungsi untuk mengirim notifikasi ke Telegram
def send_notification_telegram(software_name, mungki_version, web_version):
    telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"  # Gunakan variabel lingkungan untuk token
    chat_id = "-4523501737"  # Gunakan variabel lingkungan untuk chat ID
  
    if not telegram_token or not chat_id:
        print("Telegram token atau chat ID belum diset.")
        return
    
    telegram_message = f"Update Available for {software_name}!\nMungki version: {mungki_version}\nLatest version: {web_version}"
    send_text_url = f"https://api.telegram.org/bot{telegram_token}/sendMessage"
    params = {
        'chat_id': chat_id,
        'text': telegram_message,
        'parse_mode': 'Markdown'
    }
    
    try:
        response = requests.get(send_text_url, params=params)
        response.raise_for_status()  # Akan memunculkan error jika status code tidak 200
    except requests.exceptions.RequestException as e:
        print(f"Error sending notification to Telegram: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    versions = read_current_version_csv()
    latest_notion_version = check_latest_version_notion()
    
    if latest_notion_version:
        notion_mungki_version, notion_web_version = versions.get('Notion', (None, None))

        if compare_versions(notion_mungki_version, latest_notion_version):
            print(f"Versi baru Notion tersedia: {latest_notion_version}")
            update_web_version_csv("Notion", latest_notion_version)
            send_notification_telegram("Notion", notion_mungki_version, latest_notion_version)
        else:
            print("Versi Notion sudah yang terbaru.")
    else:
        print("Tidak dapat mengambil versi terbaru Notion.")

if __name__ == "__main__":
    main()
