import requests
from bs4 import BeautifulSoup
import csv
import os
import subprocess

# Fungsi untuk mendapatkan versi terbaru Sublime Text dari halaman resmi
def check_latest_version_sublime_text():
    url = "https://www.sublimetext.com/download"
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')

        version_tag = soup.find('p', class_='latest')  # Contoh: "Version: Build 4152"
        if version_tag:
            latest_version = version_tag.text.strip().split()[-1]
            return latest_version
        else:
            print("Tidak menemukan informasi versi terbaru.")
            return None
    else:
        print(f"Gagal mengakses halaman Sublime Text. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'

    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["Sublime Text 4", "0.0.0", ""])

    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        versions = {row['Software']: (row['Munki Version'], row['Web Version']) for row in reader}

    return versions

# Fungsi untuk memperbarui Web Version di CSV
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

# Fungsi untuk memperbarui Munki Version di CSV
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

# Bandingkan versi
def compare_versions(munki_version, latest_version):
    return munki_version != latest_version

# Jalankan autopkg (opsional)
def run_autopkg():
    try:
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.SublimeText4"], check=True)
        print("Autopkg berhasil dijalankan untuk Sublime Text 4.")
        return True
    except subprocess.CalledProcessError:
        print("Autopkg gagal dijalankan.")
        return False

# 🔔 Fungsi untuk mengirim notifikasi ke Lark
def send_notification_lark(software_name, munki_version, latest_version):
    webhook_url = "https://open.larksuite.com/open-apis/bot/v2/hook/f5a3af1a-bd6a-4482-bf93-fdf9b58bfab6"
    message = {
        "msg_type": "text",
        "content": {
            "text": (
                f"🚨 Update Available for {software_name}!\n"
                f"Munki Version: {munki_version}\n"
                f"New Version  : {latest_version}\n"
                f"✅ {software_name} has been imported into MunkiAdmin."
            )
        }
    }
    try:
        response = requests.post(webhook_url, json=message)
        if response.status_code != 200:
            raise ValueError(f"Error sending to Lark: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"Error sending notification to Lark: {e}")

# Proses utama
def main():
    versions = read_current_version_csv()

    latest_version = check_latest_version_sublime_text()
    munki_version, web_version = versions.get("Sublime Text 4", (None, None))

    if latest_version and compare_versions(munki_version, latest_version):
        print(f"New version of Sublime Text 4 is available:{latest_version}")
        update_web_version_csv("Sublime Text 4", latest_version)
        if run_autopkg():
            update_munki_version_csv("Sublime Text 4", latest_version)
            send_notification_lark("Sublime Text 4", munki_version, latest_version)
    else:
        print("The version of Sublime Text 4 is already up to date.")

if __name__ == "__main__":
    main()
