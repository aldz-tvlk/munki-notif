import requests
from bs4 import BeautifulSoup
import csv
import json
import os

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
            print(f"Latest Acrobat Reader version found: {latest_version}")
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
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["Firefox", "13.0.0.1", ""])
            writer.writerow(["PDF Sam", "4.3.0", ""])
            writer.writerow(["Acrobat Reader", "24.003.20112", ""])
    
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

# Fungsi untuk mengirim notifikasi ke Slack melalui webhook
def send_notification_slack(software_name, mungki_version, web_version):
    webhook_url = "https://hooks.slack.com/services/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"  # Ganti dengan URL webhook Anda
    slack_data = {
        "text": f"Update Available for {software_name}!\nCurrent version: {mungki_version}\nLatest version: {web_version}"
    }
    
    headers = {
        'Content-Type': 'application/json',
    }
    
    try:
        response = requests.post(webhook_url, data=json.dumps(slack_data), headers=headers)
        
        # Debugging: Cetak status code dari respon Slack
        print(f"Slack response status code: {response.status_code}")
        print(f"Slack response text: {response.text}")
        
        # Cek jika respon status bukan 200, artinya ada masalah
        if response.status_code != 200:
            raise ValueError(f"Request to Slack returned an error {response.status_code}, response: {response.text}")
    except Exception as e:
        print(f"Error sending notification to Slack: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    # Baca semua versi saat ini dari file CSV
    versions = read_current_version_csv()
    
    # Cek versi terbaru dari Adobe Acrobat Reader
    latest_acrobat_reader_version = check_latest_version_acrobat_reader()
    acrobat_reader_mungki_version, acrobat_reader_web_version = versions.get('Acrobat Reader', (None, None))

    # Jika versi web dari website berbeda dengan yang ada di file CSV, perbarui dan kirim notifikasi
    if compare_versions(acrobat_reader_mungki_version, latest_acrobat_reader_version):
        print(f"Versi baru Acrobat Reader tersedia: {latest_acrobat_reader_version}")
        
        # Perbarui kolom Web Version di file CSV
        update_web_version_csv("Acrobat Reader", latest_acrobat_reader_version)
        
        # Kirim notifikasi ke Slack
        send_notification_slack("Acrobat Reader", acrobat_reader_mungki_version, latest_acrobat_reader_version)
    else:
        print("Versi Acrobat Reader sudah yang terbaru.")

if __name__ == "__main__":
    main()
