import requests
from bs4 import BeautifulSoup
import csv
import os
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager
import time
import subprocess

def check_latest_version_github_desktop():
    options = webdriver.ChromeOptions()
    options.add_argument('--headless')
    driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
    
    url = "https://desktop.github.com/release-notes/"
    driver.get(url)
    time.sleep(3)
    
    try:
        version_badge = driver.find_element(By.CLASS_NAME, 'version-badge')
        if version_badge:
            return version_badge.text
        else:
            print("Version badge not found.")
            return None
    except Exception as e:
        print(f"An error occurred: {e}")
        return None
    finally:
        driver.quit()

def read_current_version_csv():
    filename = 'current_version.csv'
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["GitHub Desktop", "3.0.0", ""])
    
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        versions = {}
        for row in reader:
            versions[row['Software']] = (row['Munki Version'], row['Web Version'])
    return versions

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

def update_munki_version_csv(software_name, new_version):
    filename = 'current_version.csv'
    with open(filename, 'r') as file:
        rows = list(csv.DictReader(file))
    for row in rows:
        if row['Software'] == software_name:
            row['Munki Version'] = new_version
    with open(filename, 'w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=["Software", "Munki Version", "Web Version"])
        writer.writeheader()
        writer.writerows(rows)
def compare_versions(Munki_version, web_version):
    return Munki_version != web_version

# 🔔 Fungsi untuk mengirim notifikasi ke Lark
def send_notification_lark(software_name, Munki_version, web_version):
    webhook_url = "https://open.larksuite.com/open-apis/bot/v2/hook/f5a3af1a-bd6a-4482-bf93-fdf9b58bfab6"  # Ganti dengan webhook kamu
    message = {
        "msg_type": "text",
        "content": {
            "text": (
                f"🔔 *Update Available: {software_name}*\n"
                f"Munki Version: {munki_version}\n"
                f"Latest Version: {web_version}\n"
                f"GitHub Desktop has been imported into MunkiAdmin."
            )
        }
    }
    try:
        response = requests.post(webhook_url, json=message)
        if response.status_code != 200:
            raise ValueError(f"Error sending to Lark: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"Error sending notification to Lark: {e}")
        
def run_autopkg():
    success = True
    failed_archs = []

    try:
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.GitHubDesktop"], check=True)
        print("Autopkg berhasil untuk Apple Silicon (arm64).")
    except subprocess.CalledProcessError:
        print("Autopkg gagal untuk Apple Silicon (arm64).")
        success = False
        failed_archs.append("Apple Silicon")

    try:
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.GitHubDesktop-x86"], check=True)
        print("Autopkg berhasil untuk Intel (x86_64).")
    except subprocess.CalledProcessError:
        print("Autopkg gagal untuk Intel (x86_64).")
        success = False
        failed_archs.append("Intel")

    if not success:
        failed_msg = "\n".join(failed_archs)
        send_notification_lark("Android Studio", "Failed Import", f"Autopkg failed for:\n{failed_msg}")

    return success

def main():
    versions = read_current_version_csv()
    latest_version = check_latest_version_github_desktop()
    local_version, web_version = versions.get('GitHub Desktop', (None, None))

    if compare_versions(local_version, latest_version):
        print(f"New version of GitHub Desktop is available: {latest_version}")
        update_web_version_csv("GitHub Desktop", latest_version)
        run_autopkg()
        update_munki_version_csv("GitHub Desktop", latest_version)
        send_notification_lark("GitHub Desktop", local_version, latest_version)
    else:
        print("The version of GitHub Desktop is already up to date.")

if __name__ == "__main__":
    main()
