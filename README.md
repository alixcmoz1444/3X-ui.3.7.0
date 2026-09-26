# جینکس | 𝙎𝙪𝙥𝙚𝙣 𝗝𝗶𝗻𝗫

**3x-ui v2.9.4 برای Railway — یک کلیک، پنل و کانفیگ کار می‌کنه**

- VLESS/WS/TLS خودکار با تمام تنظیمات بهینه
- ساب‌لینک 100% فعال
- بدون خطا روی Railway
- پنل قفف شده (حفاظت از اطلاعات)

## دیپلوی (۲ دقیقه)

1. **GitHub:** ریپو جدید بساز و فایل‌ها آپلود کن
2. **Railway:** New Project ← Deploy from GitHub
3. بعد بیلد: **Settings ← Networking ← Generate Domain**
4. یکبار **Redeploy** بزن
5. لاگ‌ها نگاه کن: `Panel` و `Sub` آدرس‌ها اونجا هستن

## متغیرها

| نام | پیش‌فرض |
|-----|------------|
| `PANEL_USERNAMED | admin |
| `PANEL_PASSWORD` | admin |
| `JINX_UUID` | (UUID اصلی) |

## کانفیگ

```
VLESS / WebSocket / TLS
Host: YOUR-DOMAIN.up.railway.app
SNI: same
ALPN: http/1.1
FP: chrome
Path: /ws/<UUID>
```

ساب‌لینک: `https://YOUR-DOMAIN.up.railway.app/sub/jinx`

## اینباند محافظت‌شده ✓

- نام‌اش تغییر ناپذیر: جینکس | Super JinX
- قابل حذف نیست
- خودش برمی‌گرده اگر پاک بشه

---

**Made with 💜 | GPL-3.0**
