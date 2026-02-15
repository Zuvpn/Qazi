# Qazi

<p align="center">
  <b>Qazi - Interactive GOST Tunnel Manager</b><br>
  مدیریت حرفه‌ای و تعاملی تانل‌های GOST (h2 / h2+tls)
</p>

---

## ✨ Features

- ✅ نصب و آپدیت رسمی GOST
- ✅ ساخت تانل به صورت Wizard مرحله‌به‌مرحله
- ✅ پشتیبانی از:
  - HTTP2 (بدون TLS)
  - HTTP2 + TLS (h2 + TLS)
- ✅ پشتیبانی از احراز هویت (user/pass)
- ✅ ساخت خودکار systemd service
- ✅ مدیریت کامل تانل‌ها:
  - Start / Stop
  - Restart
  - Status
  - Live Logs
  - Delete
- ✅ نصب با یک دستور از GitHub
- ✅ رابط CLI تمیز و ساده

---

# 🚀 Quick Install (One Command Install)

فقط این دستور را اجرا کنید:

sudo bash <(curl -fsSL https://raw.githubusercontent.com/Zuvpn/Qazi/main/install.sh)

بعد از نصب، منوی Qazi به صورت خودکار اجرا می‌شود.

---

# 📦 Manual Install (Optional)

git clone https://github.com/Zuvpn/Qazi.git
cd Qazi
chmod +x qazi
sudo mv qazi /usr/local/bin/Qazi
sudo Qazi

---

# 🛠 First Step After Install

1. گزینه 1 را بزنید
2. GOST به صورت رسمی نصب/آپدیت می‌شود
3. سپس می‌توانید تانل بسازید

---

# 🔧 Creating a Tunnel

## نقش‌ها

1️⃣ Listener (گوش‌دهنده) — معمولاً سرور خارج  
2️⃣ Connector (وصل‌شونده) — معمولاً سرور ایران  

---

# 🔐 TLS Mode (Recommended)

در حالت http+h2:

- TLS فعال است
- امکان فعال‌سازی Verify وجود دارد
- بدون دامنه هم می‌توان با:
  ?secure=true&serverName=gost.run
  استفاده کرد

---

# 📋 Managing Tunnels

هر تانل به صورت systemd service ذخیره می‌شود:

qazi-<name>.service

مسیر ذخیره تنظیمات:

/etc/qazi/tunnels.d/

---

# 🔄 Updating Qazi

برای آپدیت:

sudo bash <(curl -fsSL https://raw.githubusercontent.com/Zuvpn/Qazi/main/install.sh)

---

# 🛡 Security Recommendation

- احراز هویت را فعال کنید
- در صورت استفاده از TLS، Verify را روشن کنید
- از پورت‌های آزاد و امن استفاده کنید

---

# 👨‍💻 Project

https://github.com/Zuvpn/Qazi

---

MIT License
