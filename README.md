# Storing Notifier

Een Android-app die 5 RSS-storingsfeeds in de gaten houdt en een melding op je telefoon stuurt zodra er een storing bijkomt (of, optioneel, wanneer een storing is opgelost). Geen login, geen server — alles draait lokaal op je telefoon.

De app zelf bevat alleen de Dart-broncode. De installeerbare APK wordt automatisch gebouwd door GitHub Actions zodra je deze code naar GitHub pusht.

## Stappenplan

### 1. Nieuwe GitHub-repository aanmaken
1. Ga naar [github.com/new](https://github.com/new).
2. Geef de repository een naam, bijv. `storing-notifier`.
3. Kies "Private" (aangezien dit puur voor eigen gebruik is) of "Public", maakt niet uit.
4. **Geen** README/`.gitignore`/licentie aanvinken (die zitten al in dit project).
5. Klik op "Create repository".

### 2. Deze code naar de repository pushen
Open een terminal in deze projectmap en voer uit (vervang de URL door die van jouw nieuwe repository):

```bash
git init
git add .
git commit -m "Eerste versie Storing Notifier"
git branch -M main
git remote add origin https://github.com/<jouw-gebruikersnaam>/storing-notifier.git
git push -u origin main
```

### 3. De build automatisch laten draaien
Zodra je naar de `main`-branch pusht, start GitHub Actions vanzelf. Je kunt de voortgang volgen via het tabblad **Actions** bovenin je repository op GitHub. De build duurt de eerste keer meestal 3-5 minuten (Flutter installeren + compileren).

### 4. De APK downloaden
1. Ga naar het tabblad **Actions** in je repository.
2. Klik op de meest recente workflow-run ("Build APK").
3. Onderaan de pagina staat **Artifacts** → klik op `storing-notifier-apk` om een zip-bestand te downloaden.
4. Pak de zip uit — daar zit `app-release.apk` in.

### 5. De APK op je telefoon installeren
1. Zet `app-release.apk` op je telefoon (bijv. via e-mail naar jezelf, Google Drive, of een USB-kabel).
2. Tik op het bestand om te installeren.
3. Android vraagt waarschijnlijk om toestemming voor "installeren van onbekende apps" — sta dit toe voor de app waarmee je het bestand opent (bijv. je bestandsbeheer-app).
4. Open de app na installatie. Hij vraagt eenmalig om toestemming voor notificaties (Android 13+) — sta dit toe, anders komen er geen meldingen door.

### 6. Klaar
De app draait vanaf nu als een **foreground service**: je ziet permanent een kleine, niet-opdringerige melding ("Storing Notifier actief") in je meldingenbalk zolang de service loopt. Dat is bewust zo gebouwd (zie hieronder) en zorgt ervoor dat de controle echt elke ~20 minuten uitgevoerd wordt, in plaats van "wanneer Android daar toevallig ruimte voor heeft". Bij een nieuwe storing krijg je altijd een aparte melding; bij "opgelost" krijg je ook een melding (staat standaard aan, kun je uitzetten in de app zelf). Tik op zo'n storingsmelding om direct naar de bijbehorende storingspagina te gaan.

Bij het eerste opstarten vraagt de app twee dingen: toestemming voor notificaties, en om uitgezonderd te worden van batterijoptimalisatie. Sta beide toe — zonder die uitzondering kan Android alsnog roet in het eten gooien.

## Waarom een permanente melding? (achtergrond)
De eerste versie van deze app gebruikte een "stille" achtergrondtaak (Android WorkManager). Dat werkte, maar bleek in de praktijk onbetrouwbaar: Android classificeert apps die je zelf zelden opent (precies het gebruikspatroon van een monitor-app als deze) in steeds "luiere" gebruikscategorieën ("App Standby Buckets"), los van batterijoptimalisatie-instellingen. Daardoor kwamen meldingen soms pas na uren binnen in plaats van na ~20 minuten. Een foreground service (met bijbehorend permanent icoontje) is de enige manier om dat mechanisme te omzeilen — het is dezelfde aanpak die apps als stappentellers en uptime-monitors gebruiken.

## Wat als je later iets wilt aanpassen?
Bewerk de Dart-bestanden in `lib/`, commit en push opnieuw (`git add . && git commit -m "..." && git push`) — de workflow bouwt dan automatisch een nieuwe APK.

Wil je bijvoorbeeld het controle-interval wijzigen? Pas de `interval` aan in `lib/background/foreground_task_setup.dart` (bij `ForegroundServiceManager.init`). In tegenstelling tot de vorige WorkManager-aanpak geldt hier geen 15-minuten-ondergrens van Android zelf, maar zet 'm niet onnodig laag — dat kost batterij zonder praktisch nut voor storingspagina's die zelden wijzigen.

## Bekende beperkingen
- **Koopoverheid/DRP-feed**: er bestaat geen officiële storingen-RSS voor deze pagina. De app kijkt daarom naar de statuszin in de RSS-kanaalomschrijving van een third-party feedgenerator (`mysitemapgenerator.com`). Dit is iets minder robuust dan een officiële feed — mocht deze bron ooit stoppen met werken, dan valt deze ene feed uit zonder dat de andere 4 geraakt worden.
- **De permanente meldingsbalk-melding kan niet weggehaald worden zonder de service te stoppen** — dat is een Android-eis voor foreground services (transparantie: de gebruiker moet altijd kunnen zien dat er iets op de achtergrond draait), geen keuze van deze app.
- **Fabrikant-specifiek batterijbeheer** (Samsung, Xiaomi, Huawei, OnePlus) kan zelfs een foreground service soms nog raken, hoewel dit type service veel resistenter is dan een gewone achtergrondtaak. Zet in je telefooninstellingen batterijoptimalisatie voor deze app uit (de app vraagt dit ook zelf bij eerste gebruik) en voeg 'm toe aan eventuele "nooit slapende apps"-lijst die je toestel aanbiedt.
- De release-APK is ondertekend met Flutter's standaard debug-sleutel (gebruikelijk en prima voor eigen/sideload-gebruik, maar niet geschikt voor publicatie in de Play Store).
