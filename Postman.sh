import requests
import re
import os
import csv
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
import time

# Fungsi untuk mendapatkan versi terbaru Postman menggunakan Selenium
def check_latest_version_postman():
    url = "https://www.postman.com/release-notes/postman-app/"

    # Atur opsi untuk Chrome
    chrome_options = Options()
    chrome_options.add_argument("--headless")  # Jalankan di background
    service = Service('/opt/homebrew/bin/chromedriver')  # Ganti dengan path ke chromedriver

    # Inisialisasi WebDriver
    driver = webdriver.Chrome(service=service, options=chrome_options)

    try:
        driver.get(url)
        time.sleep(3)  # Tunggu beberapa detik untuk memastikan halaman terload

        # Mengambil elemen versi menggunakan CSS selector
        version_element = driver.find_element(By.XPATH, '//h2[contains(text(), "Postman v")]')
        
        # Ekstrak versi menggunakan regex
        version_text = version_element.text
        version_match = re.search(r'v(\d+\.\d+)', version_text)

        if version_match:
            latest_version = version_match.group(1)  # Mengambil angka versi
            #print(f"Latest Postman version found: {latest_version}")
            return latest_version
        else:
            print("Version not found.")
            return None
    except Exception as e:
        print(f"Error fetching version with Selenium: {e}")
    finally:
        driver.quit()

    return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["Postman", "None", ""])  # Ganti dengan versi yang sesuai jika perlu
    
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
    latest_postman_version = check_latest_version_postman()
    
    if latest_postman_version:
        postman_mungki_version, postman_web_version = versions.get('Postman', (None, None))

        if compare_versions(postman_mungki_version, latest_postman_version):
            print(f"Versi baru Postman tersedia: {latest_postman_version}")
            update_web_version_csv("Postman", latest_postman_version)
            send_notification_telegram("Postman", postman_mungki_version, latest_postman_version)
        else:
            print("Versi Postman sudah yang terbaru.")
    else:
        print("Tidak dapat mengambil versi terbaru.")

if __name__ == "__main__":
    main()
