import requests
from bs4 import BeautifulSoup
import csv
import os
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager
import time
import subprocess

# Fungsi untuk mendapatkan versi terbaru WebStorm menggunakan Selenium
def check_latest_version_webstorm():
    url = "https://www.jetbrains.com/webstorm/download/other.html"

    # Atur opsi untuk Chrome
    chrome_options = Options()
    chrome_options.add_argument("--headless")  # Jalankan di background
    chrome_options.add_argument("--no-sandbox")  # Required for some server environments
    chrome_options.add_argument("--disable-dev-shm-usage")  # Overcome limited resource problems

    # Initialize WebDriver using ChromeDriverManager and Service
    service = Service(ChromeDriverManager().install())
    driver = webdriver.Chrome(service=service, options=chrome_options)

    try:
        driver.get(url)
        time.sleep(3)  # Tunggu beberapa detik untuk memastikan halaman terload

        # Cari elemen paragraf yang berisi teks 'Version'
        version_element = driver.find_element(By.XPATH, "//p[contains(., 'Version')]")
        version_text = version_element.get_attribute('innerText')

        # Ekstrak versi dari teks
        latest_version = version_text.split('Version: ')[-1].split(' (')[0].strip()

        return latest_version  # Kembalikan versi dalam format yang diinginkan

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
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["WebStorm", "2023.1.0", ""])  # Ganti dengan versi yang sesuai jika perlu
    
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        versions = {}
        for row in reader:
            versions[row['Software']] = (row['Munki Version'], row['Web Version'])
    
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

# Fungsi untuk memperbarui kolom Munki Version di file CSV
def update_munki_version_csv(software_name, new_version):
    filename = 'current_version.csv'
    rows = []
    # Baca semua baris dari CSV
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        rows = list(reader)
    
    # Update versi Munki Version pada baris yang sesuai
    for row in rows:
        if row['Software'] == software_name:
            row['Munki Version'] = new_version
    
    # Tulis kembali file CSV dengan pembaruan
    with open(filename, 'w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=["Software", "Munki Version", "Web Version"])
        writer.writeheader()
        writer.writerows(rows)

# Fungsi untuk membandingkan versi
def compare_versions(Munki_version, web_version):
    return Munki_version != web_version

# Jalankan autopkg untuk download dan import ke Munki
def run_autopkg():
    success = True
    failed_archs = []

    try:
        # Jalankan untuk Apple Silicon (arm64)
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.Webstorm-CE"], check=True)
        print("Autopkg berhasil dijalankan.")
    except subprocess.CalledProcessError:
        print("Autopkg gagal.")
        success = False
        failed_archs.append("Apple Silicon (arm64)")
    
    try:
        # Jalankan untuk Intel (x86_64)
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.Webstorm-CEx86"], check=True)
        print("Autopkg berhasil dijalankan untuk Intel (x86_64).")
    except subprocess.CalledProcessError:
        print("Autopkg gagal untuk Intel (x86_64).")
        success = False
        failed_archs.append("Intel (x86_64)")

    # Kirim notifikasi jika ada yang gagal
    if not success:
        failed_msg = "\n".join(failed_archs)
        send_notification_lark("WebStorm", "Failed Import", f"Autopkg gagal untuk:\n{failed_msg}")

    return success

# Fungsi untuk mengirim notifikasi ke Lark
def send_notification_lark(software_name, munki_version, latest_version):
    webhook_url = "https://open.larksuite.com/open-apis/bot/v2/hook/f5a3af1a-bd6a-4482-bf93-fdf9b58bfab6"  # Ganti dengan webhook kamu
    headers = {"Content-Type": "application/json"}
    message = {
        "msg_type": "text",
        "content": {
            "text": (
                f"🚨 Update Available for {software_name}!\n"
                f"Munki version : {munki_version}\n"
                f"New version   : {latest_version}\n"
                f"✅ {software_name} has been imported into MunkiAdmin."
            )
        }
    }
    try:
        response = requests.post(webhook_url, headers=headers, json=message)
        if response.status_code != 200:
            raise ValueError(f"Lark webhook error {response.status_code}, response: {response.text}")
    except Exception as e:
        print(f"Error sending notification to Lark: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    versions = read_current_version_csv()
    latest_webstorm_version = check_latest_version_webstorm()
    
    if latest_webstorm_version:
        webstorm_Munki_version, webstorm_web_version = versions.get('WebStorm', (None, None))

        if compare_versions(webstorm_Munki_version, latest_webstorm_version):
            print(f"New version of WebStorm is available: {latest_webstorm_version}")
            update_web_version_csv("WebStorm", latest_webstorm_version)
            # Jalankan autopkg
            run_autopkg()
            # Perbarui kolom Munki Version di file CSV
            update_munki_version_csv("WebStorm", latest_webstorm_version)
            send_notification_lark("WebStorm", webstorm_Munki_version, latest_webstorm_version)
        else:
            print("The version of WebStorm is already up to date.")
    else:
        print("The version of WebStorm is already up to date.")

if __name__ == "__main__":
    main()
