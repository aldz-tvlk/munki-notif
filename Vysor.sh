import requests
import csv
import os
from bs4 import BeautifulSoup
import subprocess

# Token GitHub  diambil langsung dari script
Gtoken = "xxx"

# Fungsi untuk mendapatkan versi terbaru Vysor menggunakan GitHub API
def check_latest_version_vysor():
    api_url = "https://api.github.com/repos/koush/vysor.io/releases/latest"
    headers = {
        'Authorization': f'token {Gtoken}',  # Token GitHub untuk autentikasi
        'Accept': 'application/vnd.github.v3+json'
    }
    response = requests.get(api_url, headers=headers)

    if response.status_code == 200:
        data = response.json()
        latest_version = data['tag_name']
        #print(f"Latest Vysor version found: {latest_version}")
        return latest_version
    else:
        print(f"Failed to access GitHub API for Vysor. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["Vysor", "0.0.0", ""])  # Nilai default jika belum ada data
    
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

# Fungsi untuk membandingkan versi
def compare_versions(Munki_version, latest_version):
    return Munki_version != latest_version

# Jalankan autopkg untuk download dan import ke Munki
def run_autopkg():
    success = True
    failed_archs = []

    try:
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.Vysor"], check=True)
        print("Autopkg berhasil dijalankan untuk Apple Silicon (arm64).")
    except subprocess.CalledProcessError:
        print("Autopkg gagal untuk Apple Silicon (arm64).")
        success = False
        failed_archs.append("Apple Silicon (arm64)")

    if not success:
        failed_msg = "\n".join(failed_archs)
        send_notification_lark("Vysor", "Failed Import", f"Autopkg gagal untuk:\n{failed_msg}")

    return success

# 🔔 Fungsi untuk mengirim notifikasi ke Lark
def send_notification_lark(software_name, munki_version, latest_version):
    webhook_url = "https://open.larksuite.com/open-apis/bot/v2/hook/f5a3af1a-bd6a-4482-bf93-fdf9b58bfab6"  # Ganti dengan webhook kamu
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

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    versions = read_current_version_csv()
    
    latest_vysor_version = check_latest_version_vysor()
    vysor_current_version, vysor_web_version = versions.get('Vysor', (None, None))

    if compare_versions(vysor_current_version, latest_vysor_version):
        print(f"New version of Microsoft Edge is available: {latest_vysor_version}")
        update_web_version_csv("Vysor", latest_vysor_version)
        run_autopkg()
        update_munki_version_csv("Microsoft Edge", latest_vysor_version)
        send_notification_lark("Vysor", vysor_current_version, latest_vysor_version)
    else:
        print("The version of Microsoft Edge is already up to dateq.")

if __name__ == "__main__":
    main()
