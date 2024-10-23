import requests
from bs4 import BeautifulSoup
import csv
import os

# Token Telegram dan chat ID langsung di-hardcode
telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"
chat_id = "-4523501737"  # Ganti dengan chat ID yang sesuai

# Fungsi untuk mendapatkan versi terbaru Slack dari halaman unduhan Slack
def check_latest_version_slack():
    url = "https://slack.com/downloads/mac"  # Menggunakan halaman download Slack untuk macOS
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')

        # Cari elemen yang berisi nomor versi terbaru Slack
        version_tag = soup.find('span', string=lambda x: x and "Version" in x)

        if version_tag:
            # Mengambil nomor versi dari teks (misalnya, "Version 4.23.0")
            latest_version = version_tag.text.split("Version")[-1].strip()
            #print(f"Raw version string: '{version_tag.text.strip()}'")
            #print(f"Latest Slack version found: {latest_version}")
            return latest_version
        else:
            print("Could not find the latest version information on the page.")
            return None

    else:
        print(f"Failed to access Slack page. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["Slack", "0.0.0", ""])  # Nilai default jika belum ada data
    
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
        #print(f"Telegram response status code: {response.status_code}")
        #print(f"Telegram response text: {response.text}")
        
        if response.status_code != 200:
            raise ValueError(f"Error {response.status_code}, response: {response.text}")
    except Exception as e:
        print(f"Error sending notification to Telegram: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    versions = read_current_version_csv()
    
    latest_slack_version = check_latest_version_slack()
    slack_mungki_version, slack_web_version = versions.get('Slack', (None, None))

    if compare_versions(slack_mungki_version, latest_slack_version):
        print(f"New version of Slack available: {latest_slack_version}")
        
        update_web_version_csv("Slack", latest_slack_version)
        
        send_notification_telegram("Slack", slack_mungki_version, latest_slack_version)
    else:
        print("Slack is up to date.")

if __name__ == "__main__":
    main()
