import requests
from bs4 import BeautifulSoup
import csv
import os

# Fungsi untuk mendapatkan versi terbaru dari URL dinamis
def check_latest_version(software_name, url, version_identifier, version_find_function):
    response = requests.get(url)
    
    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Cari versi berdasarkan fungsi pencarian yang diberikan
        latest_version = version_find_function(soup, version_identifier)
        
        if latest_version:
            print(f"Latest {software_name} version found: {latest_version}")
            return latest_version
        else:
            print(f"{software_name} version not found.")
            return None
    else:
        print(f"Gagal mengakses halaman untuk {software_name}. Status code: {response.status_code}")
        return None

# Fungsi pencarian versi untuk Balsamiq
def find_balsamiq_version(soup, version_identifier):
    main_content = soup.find('div', {'id': 'main-content'})
    
    if main_content:
        latest_release = main_content.find('h3')
        if latest_release:
            version_list = latest_release.find_next('ul').find_all('li')
            for li in version_list:
                text = li.get_text(strip=True)
                if version_identifier in text:
                    return version_identifier
    return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    # Jika file tidak ada, buat file baru dengan nilai default
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["balsamiq", "1.1.1", ""])
    
    # Baca file CSV
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        versions = {}
        for row in reader:
            versions[row['Software']] = (row['Mungki Version'], row['Web Version'])
    
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
        writer = csv.DictWriter(file, fieldnames=["Software", "Mungki Version", "Web Version"])
        writer.writeheader()
        writer.writerows(rows)

# Fungsi untuk membandingkan versi
def compare_versions(mungki_version, web_version):
    return mungki_version != web_version

# Fungsi untuk mengirim notifikasi ke Telegram
def send_notification_telegram(software_name, mungki_version, web_version):
    telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"  # Ganti dengan token bot Telegram kamu
    chat_id = "-4523501737"  # Ganti dengan chat ID yang sesuai
    telegram_message = f"Update Available for {software_name}!\nMungki version: {mungki_version}\nLatest version: {web_version}"
    
    send_text_url = f"https://api.telegram.org/bot{telegram_token}/sendMessage"
    params = {
        'chat_id': chat_id,
        'text': telegram_message,
        'parse_mode': 'Markdown'
    }
    
    try:
        response = requests.get(send_text_url, params=params)
        if response.status_code != 200:
            raise ValueError(f"Request to Telegram returned an error {response.status_code}, response: {response.text}")
    except Exception as e:
        print(f"Error sending notification to Telegram: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    # Baca semua versi saat ini dari file CSV
    versions = read_current_version_csv()
    
    # Cek versi terbaru dari balsamiq dengan menggunakan fungsi dinamis
    balsamiq_url = "https://balsamiq.com/wireframes/desktop/release-notes/"
    latest_balsamiq_version = check_latest_version('Balsamiq', balsamiq_url, '4.8.0', find_balsamiq_version)
    balsamiq_mungki_version, balsamiq_web_version = versions.get('balsamiq', (None, None))

    # Jika versi web dari website berbeda dengan yang ada di file CSV, perbarui dan kirim notifikasi
    if compare_versions(balsamiq_mungki_version, latest_balsamiq_version):
        print(f"Versi baru balsamiq tersedia: {latest_balsamiq_version}")
        
        # Perbarui kolom Web Version di file CSV
        update_web_version_csv("balsamiq", latest_balsamiq_version)
        
        # Kirim notifikasi ke Telegram
        send_notification_telegram("balsamiq", balsamiq_mungki_version, latest_balsamiq_version)
    else:
        print("Versi Balsamiq sudah yang terbaru.")

if __name__ == "__main__":
    main()
