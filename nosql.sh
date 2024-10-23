import requests
from bs4 import BeautifulSoup
import csv
import os

# Token Telegram diambil langsung dari script
telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"
chat_id = "-4523501737"  # Chat ID untuk Telegram

# URL halaman yang berisi changelog NoSQL Workbench
url = "https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkbenchDocumentHistory.html"

# Fungsi untuk mendapatkan versi terbaru NoSQL Workbench dari halaman changelog
def check_latest_version_nosql_workbench():
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Mencari semua elemen <tr> dalam tabel dan mengambil <td> pertama (versi)
        rows = soup.find_all('tr')
        
        for row in rows:
            first_td = row.find('td')
            if first_td:
                latest_version = first_td.text.strip()  # Mengambil teks versi terbaru
                return latest_version
        print("Could not find the latest version information in the table.")
        return None
    else:
        print(f"Failed to access NoSQL Workbench changelog page. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'  # Ganti nama file ke 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["NoSQL Workbench", "0.0.0", ""])  # Nilai default jika belum ada data
    
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        versions = {row['Software']: (row['Mungki Version'], row['Web Version']) for row in reader}
    
    return versions

# Fungsi untuk memperbarui kolom Web Version di file CSV
def update_web_version_csv(software_name, new_version):
    filename = 'current_version.csv'  # Ganti nama file ke 'current_version.csv'
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
        if response.status_code != 200:
            raise ValueError(f"Error {response.status_code}, response: {response.text}")
    except Exception as e:
        print(f"Error sending notification to Telegram: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    versions = read_current_version_csv()
    
    latest_nosql_version = check_latest_version_nosql_workbench()
    nosql_mungki_version, nosql_web_version = versions.get('NoSQL Workbench', (None, None))

    if compare_versions(nosql_mungki_version, latest_nosql_version):
        print(f"New version of NoSQL Workbench available: {latest_nosql_version}")
        
        update_web_version_csv("NoSQL Workbench", latest_nosql_version)
        
        send_notification_telegram("NoSQL Workbench", nosql_mungki_version, latest_nosql_version)
    else:
        print("Versi NoSQL Workbench sudah yang terbaru.")

if __name__ == "__main__":
    main()
