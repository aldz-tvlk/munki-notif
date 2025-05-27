import requests
from bs4 import BeautifulSoup
import csv
import os
import subprocess

# Fungsi untuk mendapatkan versi terbaru Burp Suite Community Edition
def check_latest_version_burp_suite():
    url = "https://portswigger.net/burp/releases/community/latest"
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')
        version_element = soup.find('h1', {'id': 'title', 'class': 'heading-2'})
        if version_element:
            version_text = version_element.get_text(strip=True)
            latest_version = version_text.split(' ')[-1]
            return latest_version
        else:
            print("Version information not found.")
            return None
    else:
        print(f"Gagal mengakses halaman. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["Burp Suite Community", "2023.7.0", ""])
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        return {row['Software']: (row['Munki Version'], row['Web Version']) for row in reader}

# Fungsi update Web Version di CSV
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

# Fungsi update Munki Version di CSV
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

# Fungsi membandingkan versi
def compare_versions(local_version, web_version):
    return local_version != web_version

# Jalankan autopkg
def run_autopkg():
    success = True
    failed_archs = []
    try:
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.BurpSuiteProfessional"], check=True)
        print("Autopkg berhasil dijalankan untuk MAC.")
    except subprocess.CalledProcessError:
        print("Autopkg gagal.")
        success = False
        failed_archs.append("Apple Silicon (arm64)")
    try:
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.Burp Suite Professionalx86"], check=True)
        print("Autopkg berhasil dijalankan untuk Intel (x86_64).")
    except subprocess.CalledProcessError:
        print("Autopkg gagal untuk Intel (x86_64).")
        success = False
        failed_archs.append("Intel (x86_64)")
    if not success:
        failed_msg = "\n".join(failed_archs)
        send_notification_lark("Burp Suite Community", "Failed Import", f"Autopkg gagal untuk:\n{failed_msg}")
    return success

# Fungsi mengirim notifikasi ke Lark
def send_notification_lark(software_name, local_version, web_version):
    lark_webhook_url = "https://open.larksuite.com/open-apis/bot/v2/hook/f5a3af1a-bd6a-4482-bf93-fdf9b58bfab6"  # Ganti dengan webhook URL kamu
    headers = {"Content-Type": "application/json"}
    message = {
        "msg_type": "text",
        "content": {
            "text": (
                f"🚨 Update Available: {software_name}!\n"
                f"Munki Version: {local_version}\n"
                f"New Version  : {web_version}\n"
                f"✅ {software_name} has been imported into MunkiAdmin."
            )
        }
    }
    try:
        response = requests.post(lark_webhook_url, json=message, headers=headers)
        if response.status_code != 200:
            raise ValueError(f"Lark webhook error {response.status_code}, response: {response.text}")
    except Exception as e:
        print(f"Error sending notification to Lark: {e}")

# Proses utama
def main():
    versions = read_current_version_csv()
    latest_version = check_latest_version_burp_suite()
    local_version, web_version = versions.get('Burp Suite Community', (None, None))
    if compare_versions(local_version, latest_version):
        print(f"New version of Burp Suite Community is available: {latest_version}")
        update_web_version_csv("Burp Suite Community", latest_version)
        run_autopkg()
        update_munki_version_csv("Burp Suite Community", latest_version)
        send_notification_lark("Burp Suite Community", local_version, latest_version)
    else:
        print("The version of Burp Suite Community is already up to date.")

if __name__ == "__main__":
    main()
