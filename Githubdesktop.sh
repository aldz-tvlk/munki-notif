import requests
from bs4 import BeautifulSoup
import csv
import os
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager
import time

# Fungsi untuk mendapatkan versi terbaru GitHub Desktop dari halaman HTML menggunakan Selenium
def check_latest_version_github_desktop():
    # Setup ChromeDriver
    options = webdriver.ChromeOptions()
    options.add_argument('--headless')  # Opsional, jalankan browser tanpa GUI
    driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
    
    url = "https://desktop.github.com/release-notes/"
    driver.get(url)

    # Tunggu beberapa saat jika diperlukan untuk JavaScript memuat konten
    time.sleep(3)
    
    try:
        # Cari elemen <span> yang berisi versi menggunakan class 'version-badge'
        version_badge = driver.find_element(By.CLASS_NAME, 'version-badge')
        
        if version_badge:
            latest_version = version_badge.text
            print(f"Latest GitHub Desktop version found: {latest_version}")
            return latest_version
        else:
            print("Version badge not found.")
            return None
    except Exception as e:
        print(f"An error occurred: {e}")
        return None
    finally:
        driver.quit()


# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    # Jika file tidak ada, buat file baru dengan nilai default
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["GitHub Desktop", "3.0.0", ""])  # Default GitHub Desktop version
    
    # Baca file CSV
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
    # Baca semua baris dari CSV
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        rows = list(reader)
    
    # Update versi Web Version pada baris yang sesuai
    for row in rows:
        if row['Software'] == software_name:
            row['Web Version'] = new_version
    
    # Tulis kembali file CSV dengan pembaruan
    with open(filename, 'w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=["Software", "Mungki Version", "Web Version"])
        writer.writeheader()
        writer.writerows(rows)

# Fungsi untuk membandingkan versi
def compare_versions(mungki_version, web_version):
    return mungki_version != web_version

# Fungsi untuk mengirim notifikasi ke Telegram
def send_notification_telegram(software_name, mungki_version, web_version):
    telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"   # Ganti dengan token bot Telegram kamu
    chat_id = "-4523501737"  # Ganti dengan chat ID yang sesuai
    telegram_message = f"Update Available for {software_name}!\nCurrent version: {mungki_version}\nLatest version: {web_version}"
    
    send_text_url = f"https://api.telegram.org/bot{telegram_token}/sendMessage"
    params = {
        'chat_id': chat_id,
        'text': telegram_message,
        'parse_mode': 'Markdown'  # Optional: Menggunakan Markdown untuk format pesan yang lebih baik
    }
    
    try:
        response = requests.get(send_text_url, params=params)
        
        # Debugging: Cetak status code dari respon Telegram
        print(f"Telegram response status code: {response.status_code}")
        print(f"Telegram response text: {response.text}")
        
        # Cek jika respon status bukan 200, artinya ada masalah
        if response.status_code != 200:
            raise ValueError(f"Request to Telegram returned an error {response.status_code}, response: {response.text}")
    except Exception as e:
        print(f"Error sending notification to Telegram: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    # Baca semua versi saat ini dari file CSV
    versions = read_current_version_csv()
    
    # Cek versi terbaru dari GitHub Desktop
    latest_github_desktop_version = check_latest_version_github_desktop()
    github_desktop_local_version, github_desktop_web_version = versions.get('GitHub Desktop', (None, None))

    # Jika versi web dari website berbeda dengan yang ada di file CSV, perbarui dan kirim notifikasi
    if compare_versions(github_desktop_local_version, latest_github_desktop_version):
        print(f"Versi baru GitHub Desktop tersedia: {latest_github_desktop_version}")
        
        # Perbarui kolom Web Version di file CSV
        update_web_version_csv("GitHub Desktop", latest_github_desktop_version)
        
        # Kirim notifikasi ke Telegram
        send_notification_telegram("GitHub Desktop", github_desktop_local_version, latest_github_desktop_version)
    else:
        print("Versi GitHub Desktop sudah yang terbaru.")

if __name__ == "__main__":
    main()
