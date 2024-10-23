import requests
import re
import os
import csv
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
import time

# Fungsi untuk mendapatkan versi terbaru PgAdmin 4 dari halaman release notes
def check_latest_version_pgadmin():
    url = "https://www.pgadmin.org/docs/pgadmin4/8.11/release_notes.html"

    # Mengambil konten halaman
    try:
        response = requests.get(url)
        response.raise_for_status()  # Pastikan responsnya sukses
        soup = BeautifulSoup(response.text, 'html.parser')

        # Mencari elemen yang berisi informasi versi
        version_elements = soup.select('li.toctree-l1 a')
        latest_version = None

        for element in version_elements:
            if "Version" in element.text:
                latest_version = element.text.strip()  # Mengambil teks dan menghapus spasi
                break

        if latest_version:
            # Mengambil hanya angka versi, misalnya "8.11"
            version_number = re.search(r'(\d+\.\d+)', latest_version)
            if version_number:
                return version_number.group(0)  # Mengembalikan hanya angka versi
            else:
                print("Version number not found.")
                return None
        else:
            print("No version information found.")
            return None
    except Exception as e:
        print(f"Error fetching version information: {e}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["PgAdmin 4", "None", ""])  # Ganti dengan versi yang sesuai jika perlu
    
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
    latest_pgadmin_version = check_latest_version_pgadmin()
    
    if latest_pgadmin_version:
        pgadmin_mungki_version, pgadmin_web_version = versions.get('PgAdmin 4', (None, None))

        if compare_versions(pgadmin_mungki_version, latest_pgadmin_version):
            print(f"Versi baru PgAdmin 4 tersedia: {latest_pgadmin_version}")
            update_web_version_csv("PgAdmin 4", latest_pgadmin_version)
            send_notification_telegram("PgAdmin 4", pgadmin_mungki_version, latest_pgadmin_version)
        else:
            print("Versi PgAdmin 4 sudah yang terbaru.")
    else:
        print("Tidak dapat mengambil versi terbaru.")

if __name__ == "__main__":
    main()
