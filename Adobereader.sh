import requests
from bs4 import BeautifulSoup
import csv
import json
import os
import subprocess

# Fungsi untuk mendapatkan versi terbaru Adobe Acrobat Reader dari halaman HTML
def check_latest_version_acrobat_reader():
    url = "https://www.adobe.com/devnet-docs/acrobatetk/tools/ReleaseNotesDC/index.html"
    response = requests.get(url)
    
    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Temukan semua elemen <span> yang berisi informasi versi
        version_elements = soup.find_all('span', class_='std std-ref')
        latest_version = None
        
        # Ambil versi terbaru dari elemen yang ditemukan
        if version_elements:
            for element in version_elements:
                text = element.get_text(strip=True)
                # Periksa apakah versi adalah format versi yang valid dan bukan untuk Windows Only
                if 'Windows Only' not in text:
                    latest_version = text.split(' ')[0]
                    break
        
        if latest_version:
            #print(f"Latest Acrobat Reader version found: {latest_version}")
            return latest_version
        else:
            print("Version information not found.")
            return None
    else:
        print(f"Gagal mengakses halaman. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    # Jika file tidak ada, buat file baru dengan nilai default
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["Acrobat Reader", "24.003.20112", ""])
    
    # Baca file CSV
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
    # Baca semua baris dari CSV
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        rows = list(reader)
    
    # Update versi Web Version pada baris yang sesuai
    for row in rows:
        if row['Software'] == software_name:
            row['Web Version'] = new_version
    
    # Tulis kembali file CSV dengan pembaruan
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
def compare_versions(Munki_version, web_version):
    return Munki_version != web_version

# Jalankan autopkg untuk download dan import ke Munki
def run_autopkg():
    success = True
    failed_archs = []

    try:
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.AdobeReader"], check=True)
        print("Autopkg berhasil dijalankan untuk Apple Silicon (arm64).")
    except subprocess.CalledProcessError:
        print("Autopkg gagal untuk Apple Silicon (arm64).")
        success = False
        failed_archs.append("Apple Silicon (arm64)")

    if not success:
        failed_msg = "\n".join(failed_archs)
        send_notification_lark("Acrobat Reader", "Failed Import", f"Autopkg gagal untuk:\n{failed_msg}")

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
    # Baca semua versi saat ini dari file CSV
    versions = read_current_version_csv()
    # Cek versi terbaru dari Adobe Acrobat Reader
    latest_acrobat_reader_version = check_latest_version_acrobat_reader()
    acrobat_reader_Munki_version, acrobat_reader_web_version = versions.get('Acrobat Reader', (None, None))
    # Jika versi web dari website berbeda dengan yang ada di file CSV, perbarui dan kirim notifikasi
    if compare_versions(acrobat_reader_Munki_version, latest_acrobat_reader_version):
    print(f"New version of Microsoft Edge is available: {latest_acrobat_reader_version}")    
    # Perbarui kolom Web Version di file CSV
    update_web_version_csv("Acrobat Reader", latest_acrobat_reader_version)    
    # Kirim notifikasi ke Telegram
    send_notification_lark("Acrobat Reader", acrobat_reader_Munki_version, latest_acrobat_reader_version)
    else:
        print("The version of Acrobat Reader is already up to date.")

if __name__ == "__main__":
    main()
