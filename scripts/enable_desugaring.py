"""Schakelt "core library desugaring" in voor het (in CI gegenereerde)
Android app-project. flutter_local_notifications heeft dit nodig; flutter
create zet het niet standaard aan. Werkt voor zowel build.gradle.kts
(huidige standaard) als het oudere build.gradle (Groovy)."""
import pathlib
import re

kts = pathlib.Path("android/app/build.gradle.kts")
groovy = pathlib.Path("android/app/build.gradle")
path = kts if kts.exists() else groovy
is_kts = path == kts

text = path.read_text()

if "CoreLibraryDesugaringEnabled" not in text:
    if is_kts:
        replacement = r"\1\n        isCoreLibraryDesugaringEnabled = true"
    else:
        replacement = r"\1\n        coreLibraryDesugaringEnabled true"
    text = re.sub(r"(compileOptions\s*\{)", replacement, text, count=1)

if is_kts:
    dependency_line = 'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")'
else:
    dependency_line = "coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'"

text += f"\ndependencies {{\n    {dependency_line}\n}}\n"

path.write_text(text)
print(f"Gepatcht: {path}")
