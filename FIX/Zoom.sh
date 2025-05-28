import requests
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
import csv
import os
import time
import subprocess

# Fungsi untuk mendapatkan versi terbaru Zoom dari halaman download
def check_latest_version_zoom():
    url = "https://zoom.us/download"

    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")

    service = Service('/opt/homebrew/bin/chromedriver')  # Sesuaikan path chromedriver

    try:
        driver = webdriver.Chrome(service=service, options=chrome_options)
        driver.get(url)
        time.sleep(3)

        version_element = driver.find_element(By.CLASS_NAME, "version-detail")
        latest_version = version_element.text.strip() if version_element else None
        driver.quit()
        return latest_version
    except Exception as e:
        print(f"Error fetching the version: {e}")
        return None

# Baca versi dari CSV
def read_current_version_csv():
    filename = 'current_version.csv'

    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["Zoom", "0.0.0", ""])

    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        return {row['Software']: (row['Munki Version'], row['Web Version']) for row in reader}

# Perbarui Web Version di CSV
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

# Perbarui Munki Version di CSV
def update_munki_version_csv(software_name, new_version):
    filename = 'current_version.csv'
    rows = []

    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        rows = list(reader)

    for row in rows:
        if row['Software'] == software_name:
            row['Munki Version'] = new_version

    with open(filename, 'w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=["Software", "Munki Version", "Web Version"])
        writer.writeheader()
        writer.writerows(rows)

# Bandingkan versi Munki dan versi terbaru
def compare_versions(munki_version, web_version):
    return munki_version != web_version

# Jalankan autopkg untuk Apple Silicon dan Intel
def run_autopkg():
    success = True
    failed_archs = []

    try:
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.zoom"], check=True)
        print("Autopkg berhasil untuk Apple Silicon.")
    except subprocess.CalledProcessError:
        print("Autopkg gagal untuk Apple Silicon.")
        success = False
        failed_archs.append("Apple Silicon")

    try:
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.zoomx86"], check=True)
        print("Autopkg berhasil untuk Intel.")
    except subprocess.CalledProcessError:
        print("Autopkg gagal untuk Intel.")
        success = False
        failed_archs.append("Intel")

    if not success:
        failed_msg = "\n".join(failed_archs)
        send_notification_lark("Zoom", "Failed Import", f"Autopkg gagal untuk:\n{failed_msg}")

    return success

# Kirim notifikasi ke Lark
def send_notification_lark(software_name, munki_version, latest_version):
    webhook_url = "https://open.larksuite.com/open-apis/bot/v2/hook/f5a3af1a-bd6a-4482-bf93-fdf9b58bfab6"  # Ganti dengan Webhook URL Lark kamu
    headers = {"Content-Type": "application/json"}
    message = {
        "msg_type": "text",
        "content": {
            "text": (
                f"🚨 Update Available for {software_name}!\n"
                f"Munki version: {munki_version}\n"
                f"New version  : {latest_version}\n"
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

# Proses utama
def main():
    versions = read_current_version_csv()
    latest_version = check_latest_version_zoom()

    if latest_version:
        munki_version, _ = versions.get("Zoom", ("0.0.0", ""))

        if compare_versions(munki_version, latest_version):
            print(f"New version of Zoom is available: {latest_version}")
            update_web_version_csv("Zoom", latest_version)
            run_autopkg()
            update_munki_version_csv("Zoom", latest_version)
            send_notification_lark("Zoom", munki_version, latest_version)
        else:
            print("The version of Zoom is already up to date.")
    else:
        print("The version of Zoom is already up to date.")

if __name__ == "__main__":
    main()
