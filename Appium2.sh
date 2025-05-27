import requests
import csv
import os
import subprocess

Gtoken = "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"
# Fungsi untuk mendapatkan versi terbaru Appium Inspector dari GitHub
def check_latest_version_appium():
    url = "https://api.github.com/repos/appium/appium-inspector/releases/latest"
    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": "Bearer ghp_xxx"  # Ganti dengan token GitHub kamu
    }

    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        data = response.json()
        tag = data.get("tag_name", "")
        return tag.lstrip("v")
    else:
        print(f"Gagal mendapatkan versi dari GitHub. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["Appium Inspector", "0.0.0", ""])
    
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
def compare_versions(munki_version, latest_version):
    return munki_version != latest_version

# Jalankan autopkg untuk download dan import ke Munki
def run_autopkg():
    success = True
    failed_archs = []

    try:
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.Appium-Inspector"], check=True)
        print("Autopkg berhasil dijalankan.")
    except subprocess.CalledProcessError:
        print("Autopkg gagal dijalankan.")
        success = False
        failed_archs.append("Appium Inspector MAC")

    try:
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.Appium-Inspectorx86"], check=True)
        print("Autopkg berhasil untuk Intel (x86_64).")
    except subprocess.CalledProcessError:
        print("Autopkg gagal untuk Intel (x86_64).")
        success = False
        failed_archs.append("Appium Inspector Intel")

    if not success:
        failed_msg = "\n".join(failed_archs)
        send_notification_lark("Appium Inspector", "Failed Import", f"Autopkg gagal:\n{failed_msg}")

    return success

# 🔔 Fungsi untuk mengirim notifikasi ke Lark
def send_notification_lark(software_name, munki_version, latest_version):
    webhook_url = "https://open.larksuite.com/open-apis/bot/v2/hook/xxxx-xxxx"  # Ganti dengan Webhook Lark kamu
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
    latest_version = check_latest_version_appium()
    munki_version, web_version = versions.get('Appium Inspector', (None, None))

    if latest_version and compare_versions(munki_version, latest_version):
        print(f"New version of Android Studio is available: {latest_version}")
        update_web_version_csv("Appium Inspector", latest_version)
        run_autopkg()
        update_munki_version_csv("Appium Inspector", latest_version)
        send_notification_lark("Appium Inspector", munki_version, latest_version)
    else:
        print("The version of Android Studio is already up to date.")

if __name__ == "__main__":
    main()
