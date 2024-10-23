import os
import csv
import time
import requests
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager

# Ganti dengan token bot Telegram dan chat ID yang sesuai
TELEGRAM_TOKEN = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"  # Ganti dengan token bot Telegram kamu
CHAT_ID = "-4523501737"  # Ganti dengan chat ID yang sesuai

# Fungsi untuk mendapatkan versi terbaru IntelliJ IDEA Community dari halaman resmi menggunakan Selenium
def check_latest_version_intellij():
    url = "https://www.jetbrains.com/idea/download/other.html"

# Atur opsi untuk Chrome
    chrome_options = Options()
    chrome_options.add_argument("--headless")  # Jalankan di background
    chrome_options.add_argument("--no-sandbox")  # Required for some server environments
    chrome_options.add_argument("--disable-dev-shm-usage")  # Overcome limited resource problems

    # Initialize WebDriver using ChromeDriverManager and Service
    service = Service(ChromeDriverManager().install())  # Create the service using ChromeDriverManager
    driver = webdriver.Chrome(service=service, options=chrome_options)  # Pass the service and options

    try:
        driver.get(url)
        time.sleep(5)  # Wait for page to load

        # Find the element containing the version
        version_element = driver.find_element(By.CSS_SELECTOR, "div[data-test='select-content']")

        if version_element:
            latest_version = version_element.text.strip()  # Extract and clean the text
            #print(f"Latest IntelliJ version found: {latest_version}")
            return latest_version

        print("Version information not found.")
        return None
    except Exception as e:
        print(f"Error fetching the version: {e}")
        return None
    finally:
        driver.quit()  # Close the browser

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = '/home/clouduser/software/list/current_version.csv'

    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["IntelliJ IDEA CE", "1.0.0", ""])  # Ganti dengan versi yang sesuai jika perlu

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
    telegram_message = f"Update Available for {software_name}!\nMungki version: {mungki_version}\nLatest version: {web_version}"
    send_text_url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
    params = {
        'chat_id': CHAT_ID,
        'text': telegram_message,
        'parse_mode': 'Markdown'
    }

    try:
        response = requests.get(send_text_url, params=params)
        response.raise_for_status()

        #print(f"Telegram response status code: {response.status_code}")
        #print(f"Telegram response text: {response.text}")
    except requests.exceptions.RequestException as e:
        print(f"Error sending notification to Telegram: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    versions = read_current_version_csv()
    latest_intellij_version = check_latest_version_intellij()

    if latest_intellij_version:
        intellij_mungki_version, intellij_web_version = versions.get('IntelliJ IDEA CE', (None, None))

        if compare_versions(intellij_mungki_version, latest_intellij_version):
            print(f"Versi baru IntelliJ IDEA CE tersedia: {latest_intellij_version}")
            update_web_version_csv("IntelliJ IDEA CE", latest_intellij_version)
            send_notification_telegram("IntelliJ IDEA CE", intellij_mungki_version, latest_intellij_version)
        else:
            print("Versi IntelliJ IDEA CE sudah yang terbaru.")
    else:
        print("Tidak dapat mengambil versi terbaru.")

if __name__ == "__main__":
    main()