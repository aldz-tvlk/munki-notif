import requests
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
import csv
import os
import time

# Ganti dengan token bot Telegram dan chat ID yang sesuai
TELEGRAM_TOKEN = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"  # Ganti dengan token bot Telegram kamu
CHAT_ID = "-4523501737"  # Ganti dengan chat ID yang sesuai

# Fungsi untuk mendapatkan versi terbaru Zoom dari halaman download
def check_latest_version_zoom():
    url = "https://zoom.us/download"
    
    # Set up Selenium WebDriver (Chrome in headless mode)
    chrome_options = Options()
    chrome_options.add_argument("--headless")  # Run browser in headless mode
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    
    # Make sure to specify the correct path to your chromedriver
    service = Service('/opt/homebrew/bin/chromedriver')  # Replace with your path to ChromeDriver
    
    try:
        driver = webdriver.Chrome(service=service, options=chrome_options)
        driver.get(url)
        time.sleep(3)  # Allow time for the page to load

        # Look for the element that contains the version information
        version_element = driver.find_element(By.CLASS_NAME, "version-detail")
        latest_version = None
        
        if version_element:
            # Extract and clean up the version string
            latest_version = version_element.text.strip()
            print(f"Latest Zoom version found: {latest_version}")
            driver.quit()
            return latest_version
        
        print("Version information not found.")
        driver.quit()
        return None
    except Exception as e:
        print(f"Error fetching the version: {e}")
        return None
# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["Zoom", "1.0.0", ""])  # Ganti dengan versi yang sesuai jika perlu
    
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
    telegram_message = f"Update Available for {software_name}!\nCurrent version: {mungki_version}\nLatest version: {web_version}"
    send_text_url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
    params = {
        'chat_id': CHAT_ID,
        'text': telegram_message,
        'parse_mode': 'Markdown'
    }
    
    try:
        response = requests.get(send_text_url, params=params)
        response.raise_for_status()  # Akan memunculkan error jika status code tidak 200
        
        print(f"Telegram response status code: {response.status_code}")
        print(f"Telegram response text: {response.text}")
    except requests.exceptions.RequestException as e:
        print(f"Error sending notification to Telegram: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    versions = read_current_version_csv()
    latest_zoom_version = check_latest_version_zoom()
    
    if latest_zoom_version:
        zoom_mungki_version, zoom_web_version = versions.get('Zoom', (None, None))

        if compare_versions(zoom_mungki_version, latest_zoom_version):
            print(f"Versi baru Zoom tersedia: {latest_zoom_version}")
            update_web_version_csv("Zoom", latest_zoom_version)
            send_notification_telegram("Zoom", zoom_mungki_version, latest_zoom_version)
        else:
            print("Versi Zoom sudah yang terbaru.")
    else:
        print("Tidak dapat mengambil versi terbaru.")

if __name__ == "__main__":
    main()
