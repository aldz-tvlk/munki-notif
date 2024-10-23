import requests
from bs4 import BeautifulSoup
import csv
import os

# Token GitHub dan Telegram diambil langsung dari script
Gtoken = "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"
telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"
chat_id = "-4523501737"  # Chat ID untuk Telegram

# Fungsi untuk mendapatkan versi terbaru Tableau Desktop dari website
def check_latest_version_tableau():
    url = "https://www.tableau.com/support/releases"
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Mencari semua tautan yang mengandung versi Tableau Desktop
        version_tags = soup.find_all('a', class_='cta')

        # Mengambil versi terbaru dari tautan yang ditemukan
        for tag in version_tags:
            if 'View the current version' in tag.text:  # Mencari teks yang relevan
                latest_version = tag.text.split()[-1]  # Ambil bagian terakhir yang biasanya adalah versi
                #print(f"Raw version string: '{tag.text.strip()}'")  # Untuk debugging
                #print(f"Latest Tableau Desktop version found: {latest_version}")
                return latest_version

    else:
        print(f"Failed to access Tableau releases page. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["Tableau Desktop", "0.0.0", ""])  # Nilai default jika belum ada data
    
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        versions = {row['Software']: (row['Mungki Version'], row['Web Version']) for row in reader}
    
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
        writer = csv.DictWriter(file, fieldnames=["Software", "Mungki Version", "Web Version"])
        writer.writeheader()
        writer.writerows(rows)

# Fungsi untuk membandingkan versi
def compare_versions(mungki_version, latest_version):
    return mungki_version != latest_version

# Fungsi untuk mengirim notifikasi ke Telegram
def send_notification_telegram(software_name, mungki_version, latest_version):
    telegram_message = (f"Update Available for {software_name}!\n"
                        f"Mungki version: {mungki_version}\n"
                        f"Latest version: {latest_version}")
    
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
    
    latest_tableau_version = check_latest_version_tableau()
    tableau_mungki_version, tableau_web_version = versions.get('Tableau Desktop', (None, None))

    if compare_versions(tableau_mungki_version, latest_tableau_version):
        print(f"New version of Tableau Desktop available: {latest_tableau_version}")
        
        update_web_version_csv("Tableau Desktop", latest_tableau_version)
        
        send_notification_telegram("Tableau Desktop", tableau_mungki_version, latest_tableau_version)
    else:
        print("Tableau Desktop is up to date.")

if __name__ == "__main__":
    main()
