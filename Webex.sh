import requests
from bs4 import BeautifulSoup
import csv
import os

# Fungsi untuk mendapatkan versi terbaru Webex (Mac) dari halaman
def check_latest_version_webex_mac():
    url = "https://help.webex.com/en-us/article/mqkve8/Webex-App-%7C-Release-notes"
    try:
        response = requests.get(url)
        response.raise_for_status()  # Akan memunculkan error jika status code tidak 200
        
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Cari elemen <p> yang berisi teks "Mac—" dan ambil versinya
        version_element = soup.find('p', string=lambda s: s and 'Mac—' in s)
        
        if version_element:
            latest_version = version_element.get_text(strip=True).replace('Mac—', '')
            #print(f"Latest Webex version for Mac found: {latest_version}")
            return latest_version
        
        print("Version information for Mac not found.")
        return None
    except requests.exceptions.RequestException as e:
        print(f"Error fetching the version: {e}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["Webex Mac", "44.9.0", ""])  # Ganti dengan versi yang sesuai jika perlu
    
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

# Fungsi untuk membandingkan versi
def compare_versions(Munki_version, web_version):
    return Munki_version != web_version

# Fungsi untuk mengirim notifikasi ke Telegram
def send_notification_telegram(software_name, Munki_version, web_version):
    telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"  # Ganti dengan token bot Telegram kamu
    chat_id = "-4523501737"  # Ganti dengan chat ID yang sesuai
    if not telegram_token or not chat_id:
        print("Telegram token atau chat ID belum diset.")
        return
    
    telegram_message = f"Update Available for {software_name}!\nMunki version: {Munki_version}\nLatest version: {web_version}"
    send_text_url = f"https://api.telegram.org/bot{telegram_token}/sendMessage"
    params = {
        'chat_id': chat_id,
        'text': telegram_message,
        'parse_mode': 'Markdown'
    }
    
    try:
        response = requests.get(send_text_url, params=params)
        response.raise_for_status()  # Akan memunculkan error jika status code tidak 200
        
        #print(f"Telegram response status code: {response.status_code}")
        #print(f"Telegram response text: {response.text}")
    except requests.exceptions.RequestException as e:
        print(f"Error sending notification to Telegram: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    versions = read_current_version_csv()
    latest_webex_version_mac = check_latest_version_webex_mac()
    
    if latest_webex_version_mac:
        webex_Munki_version, webex_web_version = versions.get('Webex Mac', (None, None))

        if compare_versions(webex_Munki_version, latest_webex_version_mac):
            print(f"Version baru Webex untuk Mac tersedia: {latest_webex_version_mac}")
            update_web_version_csv("Webex Mac", latest_webex_version_mac)
            send_notification_telegram("Webex Mac", webex_Munki_version, latest_webex_version_mac)
        else:
            print("Version Webex untuk Mac sudah yang terbaru.")
    else:
        print("Tidak dapat mengambil versi terbaru untuk Mac.")

if __name__ == "__main__":
    main()
