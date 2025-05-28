import requests
from bs4 import BeautifulSoup
import csv
import os
import re
import subprocess

# URL to check Chrome Stable Channel updates
url = "https://chromereleases.googleblog.com/search/label/Stable%20updates"

# Function to get the latest version of Chrome using requests and BeautifulSoup
def check_latest_version_chrome():
    response = requests.get(url)
    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')

        # Cari elemen post yang berisi 'Stable Channel Update for Desktop'
        posts = soup.find_all('div', class_='post')
        
        for post in posts:
            title_element = post.find('h2', class_='title')
            if title_element and "Stable Channel Update for Desktop" in title_element.get_text():
                # Temukan konten dalam post
                post_content = post.find('div', class_='post-body')
                if post_content:
                    version_text = post_content.get_text()
                    
                    # Gunakan regex untuk mencari versi Chrome
                    version_match = re.findall(r'(\d{2,3}\.\d+\.\d+\.\d+)', version_text)

                    if version_match:
                        # Ambil versi terbaru dari hasil pencarian
                        latest_version = version_match[-1]  # Biasanya versi terbaru ada di akhir
                        
                        # Cek apakah versi sesuai dengan yang dicari
                        if latest_version == latest_version:
                            #print(f"Version found: {latest_version}")  # Debugging output

                            return latest_version
                        else:
                            print(f"Found version: {latest_version}, but it's not the expected version.")
                    else:
                        print("Could not find version number in the text.")
                break  # Keluar dari loop jika sudah menemukan post
        
        print("Could not find 'Stable Channel Update for Desktop' post.")
        return None
    else:
        print(f"Failed to access Chrome update page. Status code: {response.status_code}")
        return None

# Function to read the current version from the CSV file
def read_current_version_csv():
    filename = 'current_version.csv'

    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["Google Chrome", "0.0.0", ""])  # Default value if no data exists yet

    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        versions = {row['Software']: (row['Munki Version'], row['Web Version']) for row in reader}

    return versions

# Function to update the web version column in the CSV file
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

# Function to compare versions
def compare_versions(Munki_version, latest_version):
    return Munki_version != latest_version

# Jalankan autopkg untuk download dan import ke Munki
def run_autopkg():
    success = True
    failed_archs = []

    try:
        # Jalankan untuk Apple Silicon (arm64)
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.chrome"], check=True)
        print("Autopkg berhasil dijalankan.")
    except subprocess.CalledProcessError:
        print("Autopkg gagal.")
        success = False
        failed_archs.append("Apple Silicon (arm64)")

    # Kirim notifikasi jika ada yang gagal
    if not success:
        failed_msg = "\n".join(failed_archs)
        send_notification_lark("Google Chrome", "Failed Import", f"Autopkg gagal untuk:\n{failed_msg}")

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

# Main process to check the version and update if necessary
def main():
    versions = read_current_version_csv()

    latest_chrome_version = check_latest_version_chrome()
    chrome_Munki_version, chrome_web_version = versions.get('Google Chrome', (None, None))

    if latest_chrome_version and compare_versions(chrome_Munki_version, latest_chrome_version):
        print(f"New version of Google Chrome is available: {latest_chrome_version}")
        update_web_version_csv("Google Chrome", latest_chrome_version)
        # Jalankan autopkg
        run_autopkg()
        # Perbarui kolom Munki Version di file CSV
        update_munki_version_csv("Google Chrome", latest_chrome_version)
        send_notification_lark("Google Chrome", chrome_Munki_version, latest_chrome_version)
    else:
        print("Version Google Chrome sudah yang terbaru.")

if __name__ == "__main__":
    main()
