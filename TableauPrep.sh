import requests
from bs4 import BeautifulSoup
import csv
import os
import subprocess

# Token GitHub dan Telegram diambil langsung dari script
Gtoken = "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"
telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"
chat_id = "-4523501737"  # Chat ID untuk Telegram

# Fungsi untuk mendapatkan versi terbaru Tableau Prep Builder dari website
def check_latest_version_tableau_prep():
    url = "https://www.tableau.com/support/releases/prep"
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Mencari semua tautan yang berisi versi Tableau Prep Builder
        version_tags = soup.find_all('a', class_='cta')
        
        # Mengambil versi terbaru dari tautan yang ditemukan
        for tag in version_tags:
            if 'View the current version' in tag.text:  # Mencari teks yang relevan
                latest_version = tag.text.split()[-1]  # Ambil bagian terakhir yang biasanya adalah versi
                #print(f"Raw version string: '{tag.text.strip()}'")  # Untuk debugging
                #print(f"Latest Tableau Prep Builder version found: {latest_version}")
                return latest_version

    else:
        print(f"Failed to access Tableau Prep Builder releases page. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["Tableau Prep Builder", "0.0.0", ""])  # Nilai default jika belum ada data
    
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
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.TableauPrep"], check=True)
        print("Autopkg berhasil dijalankan.")
    except subprocess.CalledProcessError:
        print("Autopkg gagal.")
        success = False
        failed_archs.append("Apple Silicon (arm64)")

    # Kirim notifikasi jika ada yang gagal
    if not success:
        failed_msg = "\n".join(failed_archs)
        send_notification_telegram("Tableau Prep Builder", "Failed Import", f"Autopkg gagal untuk:\n{failed_msg}")

    return success
# Fungsi untuk mengirim notifikasi ke Telegram
def send_notification_telegram(software_name, Munki_version, latest_version):
    telegram_message = (f"Update Available for {software_name}!\n"
                        f"Munki version: {Munki_version}\n"
                        f"Latest version: {latest_version}\n"
                        f"Tableau Prep Builder is Already Import to MunkiAdmin") 
    
    send_text_url = f"https://api.telegram.org/bot{telegram_token}/sendMessage"
    params = {
        'chat_id': chat_id,
        'text': telegram_message,
        'parse_mode': 'Markdown'
    }
    
    try:
        response = requests.get(send_text_url, params=params)
        #print(f"Telegram response status code: {response.status_code}")
        #print(f"Telegram response text: {response.text}")
        
        if response.status_code != 200:
            raise ValueError(f"Error {response.status_code}, response: {response.text}")
    except Exception as e:
        print(f"Error sending notification to Telegram: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    versions = read_current_version_csv()
    
    latest_tableau_prep_version = check_latest_version_tableau_prep()
    tableau_prep_Munki_version, tableau_prep_web_version = versions.get('Tableau Prep Builder', (None, None))

    if compare_versions(tableau_prep_Munki_version, latest_tableau_prep_version):
        print(f"Version baru Tableau Prep Builder tersedia: {latest_tableau_prep_version}")
        update_web_version_csv("Tableau Prep Builder", latest_tableau_prep_version)
        # Jalankan autopkg
        run_autopkg()
        # Perbarui kolom Munki Version di file CSV
        update_munki_version_csv("Tableau Prep Builder", latest_tableau_prep_version)
        send_notification_telegram("Tableau Prep Builder", tableau_prep_Munki_version, latest_tableau_prep_version)
    else:
        print("Version Tableau Prep Builder sudah yang terbaru.")

if __name__ == "__main__":
    main()
