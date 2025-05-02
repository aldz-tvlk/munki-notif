import requests
from bs4 import BeautifulSoup
import csv
import os
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager
import time

# Token Telegram dan chat ID
telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"
chat_id = "-4523501737"  # Ganti dengan chat ID yang sesuai

# Konfigurasi Selenium
chrome_options = Options()
chrome_options.add_argument("--headless")  # Menjalankan tanpa GUI
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-dev-shm-usage")
chrome_options.add_argument("--disable-blink-features=AutomationControlled")
chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
chrome_options.add_experimental_option("useAutomationExtension", False)

# Inisialisasi WebDriver
driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=chrome_options)

def get_arc_browser_version():
    try:
        driver.get(url)
        time.sleep(3)  # Tunggu halaman dimuat
        
        # Cari elemen yang berisi versi (pastikan selector sesuai dengan elemen yang benar)
        version_element = driver.find_element(By.CSS_SELECTOR, "h1.article-title")  # Sesuaikan dengan elemen yang benar
        version_text = version_element.text.strip()
        
        return version_text
    except Exception as e:
        print(f"Error: {e}")
        return None
    finally:
        driver.quit()

        
# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["Arc Browser", "0.0.0", ""])  # Nilai default jika belum ada data
    
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        versions = {row['Software']: (row['Munki Version'], row['Web Version']) for row in reader}
    
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
        writer = csv.DictWriter(file, fieldnames=["Software", "Munki Version", "Web Version"])
        writer.writeheader()
        writer.writerows(rows)

# Fungsi untuk membandingkan versi
def compare_versions(Munki_version, latest_version):
    return Munki_version != latest_version

# Fungsi untuk mengirim notifikasi ke Telegram
def send_notification_telegram(software_name, Munki_version, latest_version):
    telegram_message = (f"Update Available for {software_name}!\n"
                        f"Munki Version: {Munki_version}\n"
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
    
    latest_arc_version = check_latest_version_arc()
    arc_Munki_version, arc_web_version = versions.get('Arc Browser', (None, None))

    if latest_arc_version and compare_versions(arc_Munki_version, latest_arc_version):
        print(f"New version of Arc Browser available: {latest_arc_version}")
        
        update_web_version_csv("Arc Browser", latest_arc_version)
        
        send_notification_telegram("Arc Browser", arc_Munki_version, latest_arc_version)
    else:
        print("Arc Browser is up to date or could not retrieve the latest version.")

if __name__ == "__main__":
    main()
