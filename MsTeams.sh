import requests
from bs4 import BeautifulSoup
import csv
import os
import subprocess

# Token Telegram dan chat ID
telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"
chat_id = "-4523501737"  # Ganti dengan chat ID yang sesuai

# Fungsi untuk mendapatkan versi terbaru Microsoft Teams dari halaman rilis
def check_latest_version_teams():
    url = "https://learn.microsoft.com/en-us/officeupdates/teams-app-versioning"
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')

        # Mencari semua baris dalam tabel
        rows = soup.find_all('tr')
        if rows:
            # Ambil baris pertama setelah header (baris kedua)
            first_row_data = rows[1].find_all('td')
            if len(first_row_data) >= 4:
                latest_version = first_row_data[2].text.strip()  # Ambil kolom ke-4 yang berisi Teams version
                #print(f"Latest Microsoft Teams version found: {latest_version}")
                return latest_version
            else:
                print("Could not find the correct number of columns in the first data row.")
        else:
            print("No rows found in the table.")
        return None

    else:
        print(f"Failed to access Microsoft Teams page. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["Microsoft Teams", "0.0.0", ""])  # Nilai default jika belum ada data
    
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
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.MSTeams"], check=True)
        print("Autopkg berhasil dijalankan.")
    except subprocess.CalledProcessError:
        print("Autopkg gagal.")
        success = False
        failed_archs.append("Apple Silicon (arm64)")

    # Kirim notifikasi jika ada yang gagal
    if not success:
        failed_msg = "\n".join(failed_archs)
        send_notification_telegram("Microsoft Teams", "Failed Import", f"Autopkg gagal untuk:\n{failed_msg}")

    return success

# Fungsi untuk mengirim notifikasi ke Telegram
def send_notification_telegram(software_name, Munki_version, latest_version):
    telegram_message = (f"Update Available for {software_name}!\n"
                        f"Munki Version: {Munki_version}\n"
                        f"Latest version: {latest_version}\n"
                        f"Microsoft Teams is Already Import to MunkiAdmin")
    
    send_text_url = f"https://api.telegram.org/bot{telegram_token}/sendMessage"
    params = {
        'chat_id': chat_id,
        'text': telegram_message,
        'parse_mode': 'Markdown'
    }
    
    try:
        response = requests.get(send_text_url, params=params)
        if response.status_code != 200:
            raise ValueError(f"Error {response.status_code}, response: {response.text}")
    except Exception as e:
        print(f"Error sending notification to Telegram: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    versions = read_current_version_csv()
    
    latest_teams_version = check_latest_version_teams()
    teams_Munki_version, teams_web_version = versions.get('Microsoft Teams', (None, None))

    if latest_teams_version and compare_versions(teams_Munki_version, latest_teams_version):
        print(f"Version baru Microsoft Teams tersedia: {latest_teams_version}")
        update_web_version_csv("Microsoft Teams", latest_teams_version)
        # Jalankan autopkg
        run_autopkg()
        # Perbarui kolom Munki Version di file CSV
        update_munki_version_csv("Microsoft Teams", latest_teams_version)
        send_notification_telegram("Microsoft Teams", teams_Munki_version, latest_teams_version)
    else:
        print("Version Microsoft Teams sudah yang terbaru.")

if __name__ == "__main__":
    main()
