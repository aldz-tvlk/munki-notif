import requests
from bs4 import BeautifulSoup
import csv
import os
import re

# Token Telegram dan chat ID
telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"
chat_id = "-4523501737"  # Ganti dengan chat ID yang sesuai

# Fungsi untuk mendapatkan versi terbaru Microsoft Office 365 dari halaman resmi
def check_latest_version_office():
    url = "https://learn.microsoft.com/en-us/officeupdates/update-history-office-for-mac"
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')

        # Mencari tabel yang mengandung informasi versi
        version_table = soup.find('table')
        if version_table:
            rows = version_table.find_all('tr')
            for row in rows[1:]:  # Lewati header
                cols = row.find_all('td')
                if len(cols) > 1:  # Pastikan ada cukup kolom
                    version_text = cols[1].text.strip()

                    # Cek untuk mencocokkan versi dengan format yang diinginkan
                    version_match = re.search(r'(\d+\.\d+) \((\d+)\)', version_text)
                    if version_match:
                        major_minor = version_match.group(1)  # Ambil bagian utama dan minor
                        build_number = version_match.group(2)  # Ambil build number
                        formatted_version = f"{major_minor}.{build_number}"  # Format menjadi 16.89.24091630
                        print(f"Latest Microsoft Office version found: {formatted_version}")
                        return formatted_version
                    
            # Jika tidak menemukan versi, periksa teks di seluruh halaman
            all_text = soup.get_text()
            version_match = re.search(r'(\d+\.\d+) \((\d+)\)', all_text)
            if version_match:
                major_minor = version_match.group(1)
                build_number = version_match.group(2)
                formatted_version = f"{major_minor}.{build_number}"
                print(f"Latest Microsoft Office version found in page text: {formatted_version}")
                return formatted_version

        print("Could not find the version information in the page.")
        return None

    else:
        print(f"Failed to access Microsoft Office page. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["Microsoft Office 365", "0.0.0", ""])  # Nilai default jika belum ada data
    
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
                        f"Mungki Version: {mungki_version}\n"
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
    
    latest_office_version = check_latest_version_office()
    office_mungki_version, office_web_version = versions.get('Microsoft Office 365', (None, None))

    if latest_office_version and compare_versions(office_mungki_version, latest_office_version):
        print(f"New version of Microsoft Office 365 available: {latest_office_version}")
        
        update_web_version_csv("Microsoft Office 365", latest_office_version)
        
        send_notification_telegram("Microsoft Office 365", office_mungki_version, latest_office_version)
    else:
        print("Microsoft Office 365 is up to date or could not retrieve the latest version.")

if __name__ == "__main__":
    main()
