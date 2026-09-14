"""Patcht het door 'flutter create' gegenereerde AndroidManifest.xml:
- voegt de permissies toe die de app nodig heeft (internet, notificaties,
  foreground service);
- registreert de foreground-service van flutter_foreground_task, die de
  storingscontrole betrouwbaar op schema houdt (in tegenstelling tot een
  stille achtergrondtaak, die Android soms urenlang kan uitstellen).
"""
import pathlib
import re

manifest_path = pathlib.Path("android/app/src/main/AndroidManifest.xml")
text = manifest_path.read_text()

permissions = [
    "android.permission.INTERNET",
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.RECEIVE_BOOT_COMPLETED",
    "android.permission.FOREGROUND_SERVICE",
    "android.permission.FOREGROUND_SERVICE_DATA_SYNC",
]

if "android.permission.INTERNET" not in text:
    permission_lines = "\n".join(
        f'    <uses-permission android:name="{p}" />' for p in permissions
    )
    text = re.sub(r"(<manifest[^>]*>)", r"\1\n" + permission_lines, text, count=1)

service_block = (
    "    <service\n"
    '        android:name="com.pravera.flutter_foreground_task.service.ForegroundService"\n'
    '        android:foregroundServiceType="dataSync"\n'
    '        android:exported="false" />\n'
)

if "flutter_foreground_task.service.ForegroundService" not in text:
    text = text.replace("</application>", service_block + "</application>")

manifest_path.write_text(text)
print("AndroidManifest.xml gepatcht")
print(text)
