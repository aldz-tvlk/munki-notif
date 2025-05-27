import requests
from bs4 import BeautifulSoup
import csv
import json
import os
import subprocess

# Fungsi untuk mendapatkan versi terbaru Android Studio dari website resmi
def check_latest_version_android_studio():
    url = "https://developer.android.com/studio/releases"
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')
        table = soup.find('table')
        if not table:
            print("Tabel tidak ditemukan.")
            return None

        header = table.find_all('th')
        if len(header) > 0 and header[0].get_text(strip=True) == "Android Studio version":
            rows = table.find_all('tr')
            for row in rows:
                cols = row.find_all('td')
                if len(cols) > 0:
                    version_text = cols[0].get_text(strip=True)
                    if " | " in version_text:
                        version = version_text.split(' | ')[1]
                        return version
            print("Versi terbaru Android Studio tidak ditemukan.")
            return None
        else:
            print("Header 'Android Studio version' tidak ditemukan dalam tabel.")
            return None
    else:
        print(f"Gagal mengakses halaman. Status code: {response.status_code}")
        return None

def read_current_version_csv():
    filename = 'current_version.csv'
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["Android Studio", "2024.1.1", ""])
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        return {row['Software']: (row['Munki Version'], row['Web Version']) for row in reader}

def update_web_version_csv(software_name, new_version):
    filename = 'current_version.csv'
    with open(filename, 'r') as file:
        rows = list(csv.DictReader(file))
    for row in rows:
        if row['Software'] == software_name:
            row['Web Version'] = new_version
    with open(filename, 'w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=["Software", "Munki Version", "Web Version"])
        writer.writeheader()
        writer.writerows(rows)

def update_munki_version_csv(software_name, new_version):
    filename = 'current_version.csv'
    with open(filename, 'r') as file:
        rows = list(csv.DictReader(file))
    for row in rows:
        if row['Software'] == software_name:
            row['Munki Version'] = new_version
    with open(filename, 'w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=["Software", "Munki Version", "Web Version"])
        writer.writeheader()
        writer.writerows(rows)

def compare_versions(munki_version, web_version):
    return munki_version != web_version

# Kirim notifikasi ke Lark (mengganti fungsi Telegram)
def send_notification_lark(software_name, munki_version, web_version):
    webhook_url = "https://open.larksuite.com/open-apis/bot/v2/hook/f5a3af1a-bd6a-4482-bf93-fdf9b58bfab6"
    
    message = {
        "msg_type": "text",
        "content": {
            "text": (
                f"🚨 Update Available for {software_name}!\n"
                f"Munki Version: {munki_version}\n"
                f"New Version  : {web_version}\n"
                f"✅ {software_name} has been imported into MunkiAdmin."
            )
        }
    }

    headers = {"Content-Type": "application/json"}
    
    try:
        response = requests.post(webhook_url, headers=headers, data=json.dumps(message))
        if response.status_code != 200:
            raise ValueError(f"Lark notification failed: {response.status_code}, {response.text}")
    except Exception as e:
        print(f"Error sending notification to Lark: {e}")

def run_autopkg():
    success = True
    failed_archs = []

    try:
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.AndroidStudio"], check=True)
        print("Autopkg berhasil untuk Apple Silicon (arm64).")
    except subprocess.CalledProcessError:
        print("Autopkg gagal untuk Apple Silicon (arm64).")
        success = False
        failed_archs.append("Apple Silicon")

    try:
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.AndroidStudiox86"], check=True)
        print("Autopkg berhasil untuk Intel (x86_64).")
    except subprocess.CalledProcessError:
        print("Autopkg gagal untuk Intel (x86_64).")
        success = False
        failed_archs.append("Intel")

    if not success:
        failed_msg = "\n".join(failed_archs)
        send_notification_lark("Android Studio", "Failed Import", f"Autopkg failed for:\n{failed_msg}")

    return success

def main():
    versions = read_current_version_csv()
    latest_version = check_latest_version_android_studio()
    munki_version, web_version = versions.get("Android Studio", (None, None))

    if latest_version and compare_versions(munki_version, latest_version):
        print(f"New version of Android Studio is available: {latest_version}")
        update_web_version_csv("Android Studio", latest_version)
        run_autopkg()
        update_munki_version_csv("Android Studio", latest_version)
        send_notification_lark("Android Studio", munki_version, latest_version)
    else:
        print("The version of Android Studio is already up to date.")

if __name__ == "__main__":
    main()
