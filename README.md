# Bacheca Lavoro — App Flutter

App Flutter per una bacheca di annunci di lavoro (compito EMAD).

- **Aziende**: si registrano, accedono, pubblicano annunci, consultano le candidature ricevute e aprono i curriculum.
- **Candidati**: senza registrazione consultano la bacheca, aprono il dettaglio di un annuncio e si candidano
  con nome, cognome, email, telefono (facoltativo) e curriculum in PDF.

Il back-end (Dart + SQLite) è in un repository separato: `bacheca_server`.

## Requisiti

- Flutter 3.50+ (Dart 3.14+)
- Il server `bacheca_server` in esecuzione e raggiungibile dal telefono

## Avvio

```bash
flutter pub get
flutter run            # con il telefono Android collegato via USB (debug USB attivo)
```

Oppure si può generare l'APK con `flutter build apk --release` e installarlo:
il file si trova in `build/app/outputs/flutter-apk/app-release.apk`.

### Collegare l'app al server

1. Avviare il server sul computer (`dart run bin/server.dart`): stampa l'indirizzo da usare, es. `http://192.168.1.109:8080`.
2. Telefono e computer devono essere sulla **stessa rete Wi-Fi** e la porta 8080 deve essere aperta nel firewall (vedi README del server).
3. Nell'app: icona ⚙️ in alto → **Impostazioni** → inserire l'indirizzo → *Salva e verifica connessione*.

L'indirizzo predefinito è `http://10.0.2.2:8080`, che funziona con l'emulatore Android.

## Scenari

| Scenario | Percorso nell'app |
|---|---|
| **S1** – Pubblicare un annuncio | Bacheca → *Area aziende* → *Registrati* → crea account → *Accedi* → Area riservata → *Nuovo annuncio* → *Pubblica* (l'annuncio compare anche nella bacheca) |
| **S2** – Candidarsi | Bacheca → tocca un annuncio → *Candidati* → compila il form → *Allega CV* → *Invia candidatura* → messaggio di conferma |
| **S3** – Candidature e logout | Area riservata → tocca un annuncio → tocca una candidatura → *Apri curriculum* → indietro → *Esci* → si torna alla bacheca e il pulsante mostra di nuovo *Area aziende* (login richiesto) |

Per aprire il curriculum serve un'app che legga i PDF (es. Google Drive / visualizzatore PDF di sistema).

## Struttura

```
lib/main.dart                         avvio e tema
lib/state/session.dart                indirizzo server + sessione azienda (salvati sul dispositivo)
lib/api/api_client.dart               chiamate HTTP al server
lib/api/models.dart                   Job, JobApplication, Company
lib/screens/board_screen.dart         bacheca pubblica (R5)
lib/screens/job_detail_screen.dart    dettaglio annuncio (R5)
lib/screens/apply_screen.dart         candidatura con CV (R6)
lib/screens/register_screen.dart      registrazione azienda (R1)
lib/screens/login_screen.dart         login (R2)
lib/screens/company_home_screen.dart  area riservata, logout (R3, R7)
lib/screens/new_job_screen.dart       nuovo annuncio (R4)
lib/screens/job_applications_screen.dart   candidature ricevute (R7)
lib/screens/application_detail_screen.dart dati candidato e CV (R7)
lib/screens/settings_screen.dart      indirizzo del server
test/api_test.dart                    test di client API e sessione
```
