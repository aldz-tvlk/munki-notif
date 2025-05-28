import requests
from bs4 import BeautifulSoup
import csv
import os
import subprocess

# Fungsi untuk mendapatkan versi terbaru Sourcetree dari halaman download archives
def check_latest_version_sourcetree():
    url = "https://www.sourcetreeapp.com/download-archives"
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Cari elemen <a> yang berisi nomor versi terbaru menggunakan 'string'
        version_tag = soup.find('a', href=True, string=lambda x: x and x.replace('.', '').isdigit())
        
        if version_tag:
            latest_version = version_tag.string.strip()  # Mengambil nomor versi dari teks
            #print(f"Raw version string: '{version_tag.string.strip()}'")
            #print(f"Latest Sourcetree version found: {latest_version}")
            return latest_version
        else:
            print("Could not find the latest version information on the page.")
            return None

    else:
        print(f"Failed to access Sourcetree page. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["Sourcetree", "0.0.0", ""])  # Nilai default jika belum ada data
    
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
def compare_versions(Munki_version, latest_version):
    return Munki_version != latest_version

# Jalankan autopkg untuk download dan import ke Munki
def run_autopkg():
    success = True
    failed_archs = []

    try:
        # Jalankan untuk Apple Silicon (arm64)
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.SourceTree"], check=True)
        print("Autopkg berhasil dijalankan.")
    except subprocess.CalledProcessError:
        print("Autopkg gagal.")
        success = False
        failed_archs.append("Apple Silicon (arm64)")

    # Kirim notifikasi jika ada yang gagal
    if not success:
        failed_msg = "\n".join(failed_archs)
        send_notification_lark("Sourcetree", "Failed Import", f"Autopkg gagal untuk:\n{failed_msg}")

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
    latest_sourcetree_version = check_latest_version_sourcetree()
    sourcetree_Munki_version, sourcetree_web_version = versions.get('Sourcetree', (None, None))

    if compare_versions(sourcetree_Munki_version, latest_sourcetree_version):
        print(f"New version of Sourcetree is available: {latest_sourcetree_version}")
        update_web_version_csv("Sourcetree", latest_sourcetree_version)
        # Jalankan autopkg
        run_autopkg()
        # Perbarui kolom Munki Version di file CSV
        update_munki_version_csv("Sourcetree", latest_sourcetree_version)
        send_notification_lark("Sourcetree", sourcetree_Munki_version, latest_sourcetree_version)
    else:
        print("The version of Sourcetree is already up to date.")

if __name__ == "__main__":
    main()
