<div align="center">

# 📱 Travel Companion
## Guida Completa di Avvio e Test

<br/>

[![iOS](https://img.shields.io/badge/iOS-17.0+-007AFF.svg?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![AI Features](https://img.shields.io/badge/AI_Features-iOS_26+-FF9500.svg?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/machine-learning/)
[![Swift](https://img.shields.io/badge/Swift-5.9-F05138.svg?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)

---

**Questa guida ti aiuterà a:**
- Installare l'app sul tuo iPhone
- Testare tutte le funzionalità richieste dal corso LAM
- Verificare la conformità ai requisiti universitari

</div>

---

## 📑 Indice

1. [Avvio dell'App su iPhone](#-parte-1-avvio-dellapp-su-iphone)
2. [Test Use Case - Record Activities](#-sezione-a-record-the-activities)
3. [Test Use Case - Display Charts](#-sezione-b-display-charts)
4. [Test Use Case - Background Jobs](#-sezione-c-background-jobs)
5. [Test Use Case - Funzionalità AI](#-sezione-d-funzionalità-ai-ios-26)
6. [Checklist Finale](#-checklist-finale-di-verifica)
7. [Troubleshooting](#-troubleshooting)

---

<div align="center">

# 🚀 PARTE 1: Avvio dell'App su iPhone

</div>

## 📋 Prerequisiti

| Requisito | Versione Minima | Note |
|:---------:|:---------------:|:----:|
| ![macOS](https://img.shields.io/badge/macOS-14.0+-000000?style=flat-square&logo=apple) | Sonoma 14.0+ | Per compilare |
| ![Xcode](https://img.shields.io/badge/Xcode-16.0+-147EFB?style=flat-square&logo=xcode) | 16.0+ | IDE sviluppo |
| ![iPhone](https://img.shields.io/badge/iPhone-iOS_17+-000000?style=flat-square&logo=apple) | iOS 17.0+ | Funzionalità base |
| ![AI](https://img.shields.io/badge/iPhone-iOS_26+-FF9500?style=flat-square&logo=apple) | iOS 26.0+ | Funzionalità AI |

---

## Step 1️⃣ Collega il tuo iPhone

```bash
# Collega l'iPhone al Mac via cavo USB
# Sblocca l'iPhone e clicca "Autorizza questo computer"
```

> 💡 **Tip:** Puoi anche usare la connessione WiFi dopo il primo collegamento via cavo

---

## Step 2️⃣ Configura Xcode

### Apri il progetto

```bash
open /Users/giadafranceschini/code/uni/LAM/travel_companion/TravelCompanion/TravelCompanion.xcodeproj
```

### Configura il Development Team

| Passo | Azione |
|:-----:|--------|
| 1 | Seleziona il progetto **TravelCompanion** nel Navigator (sidebar sinistra) |
| 2 | Vai al tab **Signing & Capabilities** |
| 3 | In **Team**: seleziona il tuo Apple ID |
| 4 | Se necessario, modifica il **Bundle Identifier** |

> ⚠️ **Bundle Identifier:** Se hai errori di signing, cambialo in qualcosa di unico come `com.tuonome.TravelCompanion`

---

## Step 3️⃣ Abilita Developer Mode su iPhone

<table>
<tr>
<td width="60%">

### Su iPhone (iOS 16+):

1. Apri **Impostazioni**
2. Vai a **Privacy e Sicurezza**
3. Scorri fino a **Modalità sviluppatore**
4. **Attiva** l'interruttore
5. **Riavvia** l'iPhone quando richiesto
6. Dopo il riavvio, **conferma** l'attivazione

</td>
<td width="40%" align="center">

```
⚙️ Impostazioni
    └── 🔒 Privacy e Sicurezza
            └── 👨‍💻 Modalità sviluppatore
                    └── ✅ Attiva
```

</td>
</tr>
</table>

---

## Step 4️⃣ Compila e Installa

| Passo | Azione | Shortcut |
|:-----:|--------|:--------:|
| 1 | Seleziona il tuo iPhone dal menu dispositivi (in alto) | - |
| 2 | Clicca **Run** | `⌘ + R` |
| 3 | Attendi compilazione e installazione | ~1-2 min |
| 4 | Se richiesto, autorizza lo sviluppatore su iPhone | - |

### Prima esecuzione - Autorizzazione

Se vedi "App non attendibile":

```
⚙️ Impostazioni
    └── 📱 Generali
            └── 📋 Gestione dispositivo (o VPN e gestione dispositivo)
                    └── [Tuo Apple ID]
                            └── ✅ Autorizza
```

---

<div align="center">

# 🧪 PARTE 2: Test degli Use Case

---

## 📝 SEZIONE A: Record the Activities

![Status](https://img.shields.io/badge/Requisiti-14_test-blue?style=for-the-badge)

</div>

---

### 🗺️ A1. Creazione Trip Plan

<table>
<tr>
<th>Test ID</th>
<th>Cosa Testare</th>
<th>Come</th>
<th>Risultato Atteso</th>
</tr>
<tr>
<td align="center"><code>A1.1</code></td>
<td>Inserire destinazione</td>
<td>Home → "Nuovo Viaggio" → Campo destinazione</td>
<td>✅ Campo accetta testo</td>
</tr>
<tr>
<td align="center"><code>A1.2</code></td>
<td>Selezionare data inizio</td>
<td>Tocca il date picker</td>
<td>✅ Calendario appare</td>
</tr>
<tr>
<td align="center"><code>A1.3</code></td>
<td>Selezionare data fine</td>
<td>Solo per Multi-day trip</td>
<td>✅ Appare se tipo corretto</td>
</tr>
<tr>
<td align="center"><code>A1.4</code></td>
<td>Scegliere tipo viaggio</td>
<td>Tocca segmented control</td>
<td>✅ 3 opzioni disponibili</td>
</tr>
<tr>
<td align="center"><code>A1.5</code></td>
<td>Creare il viaggio</td>
<td>Tocca "Crea Viaggio"</td>
<td>✅ Viaggio salvato</td>
</tr>
</table>

#### 🎯 Test Pratico

```
📍 SCENARIO: Creare un nuovo viaggio completo

1. 🏠 Apri l'app
2. ➕ Tocca "Nuovo Viaggio"
3. ✏️  Inserisci "Roma" come destinazione
4. 📅 Seleziona oggi come data inizio
5. 🔄 Seleziona "Multi-day Trip"
6. 📅 Seleziona data fine (+3 giorni)
7. 📍 Attiva "Inizia Tracking"
8. ✅ Tocca "Crea Viaggio"

→ VERIFICA: Sei portato alla schermata ActiveTrip con GPS attivo
```

---

### 📍 A2. Tracking GPS (Start/Stop)

<table>
<tr>
<th>Test ID</th>
<th>Cosa Testare</th>
<th>Come</th>
<th>Risultato Atteso</th>
</tr>
<tr>
<td align="center"><code>A2.1</code></td>
<td>Start tracking</td>
<td>Crea viaggio con tracking attivo</td>
<td>✅ Timer parte, GPS registra</td>
</tr>
<tr>
<td align="center"><code>A2.2</code></td>
<td>Visualizza durata</td>
<td>Guarda timer in ActiveTrip</td>
<td>✅ Tempo incrementa</td>
</tr>
<tr>
<td align="center"><code>A2.3</code></td>
<td>Visualizza coordinate</td>
<td>Guarda mappa in ActiveTrip</td>
<td>✅ Posizione mostrata</td>
</tr>
<tr>
<td align="center"><code>A2.4</code></td>
<td>Stop tracking</td>
<td>Tocca "Termina Viaggio"</td>
<td>✅ Percorso salvato</td>
</tr>
</table>

#### 🎯 Test Pratico

```
📍 SCENARIO: Testare il tracking GPS

1. 🚶 Con un viaggio attivo, cammina per almeno 50 metri
2. 👀 Osserva che il punto sulla mappa si muove
3. 📊 Verifica che "Distanza" aumenta
4. 🛑 Tocca "Termina Viaggio"

→ VERIFICA: Il percorso è salvato e visibile nel dettaglio viaggio
```

---

### 📸 A3. Allegare Foto

<table>
<tr>
<th>Test ID</th>
<th>Cosa Testare</th>
<th>Come</th>
<th>Risultato Atteso</th>
</tr>
<tr>
<td align="center"><code>A3.1</code></td>
<td>Scattare foto</td>
<td>ActiveTrip → 📷 → "Scatta Foto"</td>
<td>✅ Camera si apre</td>
</tr>
<tr>
<td align="center"><code>A3.2</code></td>
<td>Scegliere da galleria</td>
<td>ActiveTrip → 📷 → "Libreria"</td>
<td>✅ Galleria si apre</td>
</tr>
<tr>
<td align="center"><code>A3.3</code></td>
<td>Foto geolocalizzata</td>
<td>Scatta foto</td>
<td>✅ Coordinate salvate</td>
</tr>
<tr>
<td align="center"><code>A3.4</code></td>
<td>Visualizza foto</td>
<td>TripDetail → sezione Foto</td>
<td>✅ Galleria foto appare</td>
</tr>
</table>

#### 🎯 Test Pratico

```
📍 SCENARIO: Aggiungere foto al viaggio

1. 📷 Durante viaggio attivo, tocca icona fotocamera
2. 📸 Scegli "Scatta Foto"
3. 🖼️  Scatta una foto
4. ✅ Conferma
5. 🛑 Termina il viaggio
6. 📋 Vai nel dettaglio del viaggio

→ VERIFICA: La foto appare nella sezione "Foto" con data/ora
```

---

### 📝 A4. Allegare Note

<table>
<tr>
<th>Test ID</th>
<th>Cosa Testare</th>
<th>Come</th>
<th>Risultato Atteso</th>
</tr>
<tr>
<td align="center"><code>A4.1</code></td>
<td>Aggiungere nota</td>
<td>ActiveTrip → icona 📝</td>
<td>✅ Form nota appare</td>
</tr>
<tr>
<td align="center"><code>A4.2</code></td>
<td>Nota con testo</td>
<td>Scrivi testo → Salva</td>
<td>✅ Nota salvata</td>
</tr>
<tr>
<td align="center"><code>A4.3</code></td>
<td>Nota geolocalizzata</td>
<td>Automatico</td>
<td>✅ Coordinate salvate</td>
</tr>
<tr>
<td align="center"><code>A4.4</code></td>
<td>Visualizza note</td>
<td>TripDetail → sezione Note</td>
<td>✅ Lista note appare</td>
</tr>
</table>

#### 🎯 Test Pratico

```
📍 SCENARIO: Aggiungere nota al viaggio

1. 📝 Durante viaggio attivo, tocca icona nota
2. ✏️  Scrivi "Pranzo fantastico al ristorante!"
3. 💾 Tocca "Salva"
4. 🛑 Termina il viaggio
5. 📋 Vai nel dettaglio del viaggio

→ VERIFICA: La nota appare con timestamp e posizione
```

---

### 🏷️ A5. Tipi di Viaggio (3 obbligatori)

<table>
<tr>
<th align="center">Tipo</th>
<th align="center">Icona</th>
<th align="center">Colore</th>
<th>Caratteristiche</th>
</tr>
<tr>
<td><strong>Local Trip</strong></td>
<td align="center">🏠</td>
<td align="center">🟢 Verde</td>
<td>Viaggio in città, solo data inizio</td>
</tr>
<tr>
<td><strong>Day Trip</strong></td>
<td align="center">🚗</td>
<td align="center">🟠 Arancione</td>
<td>Escursione giornaliera, solo data inizio</td>
</tr>
<tr>
<td><strong>Multi-day Trip</strong></td>
<td align="center">✈️</td>
<td align="center">🟣 Viola</td>
<td>Vacanza, date inizio/fine, calcolo distanza</td>
</tr>
</table>

#### 🎯 Test Pratico

```
📍 SCENARIO: Creare tutti e 3 i tipi di viaggio

Crea 3 viaggi:

1. 🏠 "Giro in centro"
   └── Tipo: Local Trip
   └── Data: oggi

2. 🚗 "Escursione Appennino"
   └── Tipo: Day Trip
   └── Data: oggi

3. ✈️ "Vacanza Sicilia"
   └── Tipo: Multi-day
   └── Date: da oggi a +5 giorni

→ VERIFICA: Tutti e 3 appaiono nella lista con icone/colori corretti
```

---

### 💾 A6. Database Locale (Persistenza)

<table>
<tr>
<th>Test ID</th>
<th>Cosa Testare</th>
<th>Come</th>
<th>Risultato Atteso</th>
</tr>
<tr>
<td align="center"><code>A6.1</code></td>
<td>Persistenza dati</td>
<td>Chiudi e riapri app</td>
<td>✅ Dati ancora presenti</td>
</tr>
<tr>
<td align="center"><code>A6.2</code></td>
<td>Viaggi salvati</td>
<td>Lista Viaggi</td>
<td>✅ Tutti i viaggi creati</td>
</tr>
<tr>
<td align="center"><code>A6.3</code></td>
<td>Foto salvate</td>
<td>Dettaglio viaggio</td>
<td>✅ Foto persistono</td>
</tr>
<tr>
<td align="center"><code>A6.4</code></td>
<td>Note salvate</td>
<td>Dettaglio viaggio</td>
<td>✅ Note persistono</td>
</tr>
</table>

#### 🎯 Test Pratico

```
📍 SCENARIO: Verificare la persistenza dei dati

1. ➕ Crea un viaggio con foto e note
2. ❌ Chiudi completamente l'app (swipe up da app switcher)
3. 🔄 Riapri l'app

→ VERIFICA: Tutto è ancora presente (viaggi, foto, note)
```

---

<div align="center">

## 📊 SEZIONE B: Display Charts

![Status](https://img.shields.io/badge/Requisiti-6_test-green?style=for-the-badge)

</div>

---

### 🗺️ B1. Map View

<table>
<tr>
<th>Test ID</th>
<th>Cosa Testare</th>
<th>Come</th>
<th>Risultato Atteso</th>
</tr>
<tr>
<td align="center"><code>B1.1</code></td>
<td>Visualizza percorsi</td>
<td>Tab Mappa</td>
<td>✅ Polyline colorate</td>
</tr>
<tr>
<td align="center"><code>B1.2</code></td>
<td>Colori per tipo</td>
<td>Guarda i percorsi</td>
<td>✅ Verde/Arancio/Viola</td>
</tr>
<tr>
<td align="center"><code>B1.3</code></td>
<td>Marker foto</td>
<td>Tocca marker 📍</td>
<td>✅ Info foto appare</td>
</tr>
<tr>
<td align="center"><code>B1.4</code></td>
<td>Heatmap zone</td>
<td>Statistiche → Heatmap</td>
<td>✅ Zone evidenziate</td>
</tr>
</table>

#### 🎯 Test Pratico

```
📍 SCENARIO: Verificare le visualizzazioni mappa

1. ➕ Crea almeno 2 viaggi con tracking in zone diverse
2. 🗺️  Vai al tab "Mappa"
   → VERIFICA: Vedi i percorsi colorati

3. 📊 Vai al tab "Statistiche" → sezione Heatmap
   → VERIFICA: Zone visitate evidenziate
```

---

### 📈 B2. Bar Chart / Timeline

<table>
<tr>
<th>Test ID</th>
<th>Cosa Testare</th>
<th>Come</th>
<th>Risultato Atteso</th>
</tr>
<tr>
<td align="center"><code>B2.1</code></td>
<td>Viaggi per mese</td>
<td>Tab Statistiche</td>
<td>✅ Grafico a barre</td>
</tr>
<tr>
<td align="center"><code>B2.2</code></td>
<td>Distanza per mese</td>
<td>Statistiche → Distanza</td>
<td>✅ Grafico distanza</td>
</tr>
<tr>
<td align="center"><code>B2.3</code></td>
<td>Selezione anno</td>
<td>Tocca selettore anno</td>
<td>✅ Dati cambiano</td>
</tr>
<tr>
<td align="center"><code>B2.4</code></td>
<td>Interattività</td>
<td>Tocca una barra</td>
<td>✅ Dettaglio appare</td>
</tr>
</table>

#### 🎯 Test Pratico

```
📍 SCENARIO: Verificare i grafici statistiche

1. 📊 Vai al tab "Statistiche"
2. 👀 Visualizza il grafico "Viaggi per Mese"
3. 👆 Tocca una barra del grafico
   → VERIFICA: Mostra numero viaggi per quel mese

4. ⬇️  Scorri giù per vedere "Distanza per Mese"
   → VERIFICA: Grafico con km percorsi
```

---

<div align="center">

## 🔔 SEZIONE C: Background Jobs

![Status](https://img.shields.io/badge/Requisiti-8_test-orange?style=for-the-badge)

</div>

---

### 📢 C1. Notifiche Periodiche

<table>
<tr>
<th>Test ID</th>
<th>Tipo Notifica</th>
<th>Trigger</th>
<th>Messaggio</th>
</tr>
<tr>
<td align="center"><code>C1.1</code></td>
<td>🏛️ POI Nearby</td>
<td>GPS vicino a landmark</td>
<td>"Punto di interesse nelle vicinanze"</td>
</tr>
<tr>
<td align="center"><code>C1.2</code></td>
<td>⏰ Logging Reminder</td>
<td>Giornaliera ore 10:00</td>
<td>"Non hai registrato viaggi recentemente"</td>
</tr>
</table>

#### 🎯 Test Pratico - POI Nearby

```
📍 SCENARIO: Testare notifica POI

1. ✅ Abilita notifiche quando richiesto
2. 🚶 Vai vicino a un monumento/attrazione famosa
3. ⏳ Attendi qualche minuto

→ VERIFICA: Ricevi notifica "Punto di interesse nelle vicinanze"
```

#### 🎯 Test Pratico - Reminder

```
📍 SCENARIO: Testare notifica reminder (richiede tempo)

1. ❌ Non creare viaggi per un giorno
2. ⏰ Alle 10:00 del giorno dopo

→ VERIFICA: Notifica "Non hai registrato viaggi recentemente"
```

---

### 📍 C2. Geofencing

<table>
<tr>
<th>Test ID</th>
<th>Cosa Testare</th>
<th>Come</th>
<th>Risultato Atteso</th>
</tr>
<tr>
<td align="center"><code>C2.1</code></td>
<td>Creare zona</td>
<td>Impostazioni → Geofence → +</td>
<td>✅ Form zona appare</td>
</tr>
<tr>
<td align="center"><code>C2.2</code></td>
<td>Definire area</td>
<td>Mappa + raggio</td>
<td>✅ Cerchio su mappa</td>
</tr>
<tr>
<td align="center"><code>C2.3</code></td>
<td>Entry detection</td>
<td>Entra nella zona</td>
<td>✅ Notifica "Entrato in..."</td>
</tr>
<tr>
<td align="center"><code>C2.4</code></td>
<td>Exit detection</td>
<td>Esci dalla zona</td>
<td>✅ Notifica "Uscito da..."</td>
</tr>
</table>

#### 🎯 Test Pratico

```
📍 SCENARIO: Testare il geofencing completo

1. ⚙️  Vai in Impostazioni → "Gestione Zone Geofence"
2. ➕ Tocca "+" per aggiungere una zona
3. ✏️  Nomina la zona "Casa"
4. 📍 Seleziona la tua posizione attuale
5. 📏 Imposta raggio 100m
6. 💾 Salva

7. ❌ Esci dall'app
8. 🚶 Allontanati di più di 100m dalla posizione
   → VERIFICA: Ricevi notifica "Uscito da Casa"

9. 🔙 Ritorna nella zona
   → VERIFICA: Ricevi notifica "Entrato in Casa"
```

---

<div align="center">

## 🤖 SEZIONE D: Funzionalità AI (iOS 26+)

![Status](https://img.shields.io/badge/Requisiti-iOS_26+-FF9500?style=for-the-badge)
![AI](https://img.shields.io/badge/Apple_Intelligence-Required-purple?style=for-the-badge)

</div>

---

> ⚠️ **REQUISITI PER FUNZIONALITÀ AI:**
>
> | Requisito | Dettaglio |
> |-----------|-----------|
> | **Device** | iPhone 15 Pro o successivo (chip A17 Pro+) |
> | **iOS** | 26.0 o successivo |
> | **Apple Intelligence** | Deve essere abilitata in Impostazioni |

---

### 💬 D1. Chat AI Viaggio (con Tool Calling)

```
📍 SCENARIO: Usare la Chat AI per pianificare e agire

1. 🤖 Vai al tab "AI Assistant" (5° tab)
2. 💬 Tocca "Chat AI Viaggio" (pulsante verde)
3. 👀 Osserva i suggerimenti di conversazione:

   📘 TRAVEL EXPERT (5 suggerimenti):
   ├── "Consiglia destinazione" - Suggerimenti personalizzati
   ├── "Cucina locale" - Piatti tipici da provare
   ├── "Consigli sicurezza" - Precauzioni per destinazione
   ├── "Budget viaggio" - Pianificazione spese
   └── "Quando visitare" - Periodo migliore dell'anno

   🟢 AZIONI NELL'APP (3 suggerimenti con Tool Calling):
   ├── "Crea viaggio" - Crea un nuovo viaggio dall'AI
   ├── "Aggiungi nota" - Aggiungi nota al viaggio attivo
   └── "Le mie statistiche" - Mostra statistiche viaggi

4. 📝 Tocca uno starter o scrivi un messaggio
5. ✨ L'AI risponde con consigli o esegue azioni

→ VERIFICA TOOL CALLING:
   - Prova "Crea viaggio per Roma dal 15 al 20 marzo"
   - L'AI crea effettivamente il viaggio nell'app!
   - Il viaggio appare nella lista viaggi
```

---

### 📋 D2. Generazione Itinerario

```
📍 SCENARIO: Generare un itinerario AI

1. 🤖 Vai al tab "AI Assistant" (5° tab)
2. 📋 Tocca "Genera Itinerario"
3. ✏️  Inserisci:
   ├── Destinazione: "Firenze"
   ├── Giorni: 3
   ├── Tipo: Cultural
   └── Stile: Culturale
4. ✨ Tocca "Genera"

→ VERIFICA: Itinerario giorno per giorno con attività dettagliate
```

---

### 🧳 D3. Packing List

```
📍 SCENARIO: Generare una packing list AI

1. 🤖 Tab AI Assistant → "Packing List"
2. ✏️  Inserisci:
   ├── Destinazione: "Montagna"
   ├── Durata: 5 giorni
   └── Stagione: Inverno
3. ✨ Tocca "Genera"

→ VERIFICA: Lista categorizzata (documenti, abbigliamento, ecc.)

4. ☑️  Spunta alcuni item
→ VERIFICA: Checkbox funzionano, progress bar si aggiorna
```

---

### 🌍 D4. Destination Briefing

```
📍 SCENARIO: Generare un briefing destinazione

1. 🤖 Tab AI Assistant → "Briefing Destinazione"
2. ✏️  Inserisci: "Tokyo"
3. ✨ Tocca "Genera"

→ VERIFICA: Info complete su:
   ├── 🗣️  Lingua e frasi utili
   ├── 💰 Valuta
   ├── 🍜 Cultura culinaria
   ├── 🏯 Consigli culturali
   └── ⚠️  Note di sicurezza
```

---

<div align="center">

# ✅ CHECKLIST FINALE DI VERIFICA

</div>

Usa questa checklist per verificare di aver testato tutto:

### 📝 Record Activities

| # | Test | Status |
|:-:|------|:------:|
| 1 | Creare viaggio con destinazione e date | ⬜ |
| 2 | Creare Local Trip | ⬜ |
| 3 | Creare Day Trip | ⬜ |
| 4 | Creare Multi-day Trip | ⬜ |
| 5 | Start tracking GPS | ⬜ |
| 6 | Stop tracking GPS | ⬜ |
| 7 | Visualizzare percorso su mappa | ⬜ |
| 8 | Calcolo distanza (multi-day) | ⬜ |
| 9 | Scattare foto durante viaggio | ⬜ |
| 10 | Aggiungere nota durante viaggio | ⬜ |
| 11 | Foto geolocalizzata salvata | ⬜ |
| 12 | Nota geolocalizzata salvata | ⬜ |
| 13 | Filtrare viaggi per tipo | ⬜ |
| 14 | Persistenza dati dopo restart | ⬜ |

### 📊 Display Charts

| # | Test | Status |
|:-:|------|:------:|
| 1 | Map View con percorsi colorati | ⬜ |
| 2 | Heatmap zone visitate | ⬜ |
| 3 | Bar Chart viaggi per mese | ⬜ |
| 4 | Bar Chart distanza per mese | ⬜ |
| 5 | Selezione anno interattiva | ⬜ |
| 6 | Tocco su grafico mostra dettagli | ⬜ |

### 🔔 Background Jobs

| # | Test | Status |
|:-:|------|:------:|
| 1 | Notifica POI nearby | ⬜ |
| 2 | Notifica reminder | ⬜ |
| 3 | Creare zona geofence | ⬜ |
| 4 | Notifica entry geofence | ⬜ |
| 5 | Notifica exit geofence | ⬜ |

### 🤖 Funzionalità AI (iOS 26+)

| # | Test | Status |
|:-:|------|:------:|
| 1 | Chat AI Viaggio - Conversazione travel expert | ⬜ |
| 2 | Chat AI Viaggio - Tool Calling (crea viaggio) | ⬜ |
| 3 | Chat AI Viaggio - Tool Calling (aggiungi nota) | ⬜ |
| 4 | Chat AI Viaggio - Tool Calling (statistiche) | ⬜ |
| 5 | Generare itinerario | ⬜ |
| 6 | Generare packing list | ⬜ |
| 7 | Generare briefing destinazione | ⬜ |

---

<div align="center">

# 🆘 TROUBLESHOOTING

</div>

### Problemi Comuni e Soluzioni

| Problema | Soluzione |
|:--------:|-----------|
| ![Error](https://img.shields.io/badge/❌-App_non_affidabile-red) | **Impostazioni** → Generali → Gestione dispositivo → Autorizza |
| ![Error](https://img.shields.io/badge/❌-GPS_non_funziona-red) | Verifica permessi: **Impostazioni** → Privacy → Localizzazione → TravelCompanion |
| ![Error](https://img.shields.io/badge/❌-Foto_non_si_salvano-red) | Verifica permessi fotocamera e libreria foto |
| ![Error](https://img.shields.io/badge/❌-Notifiche_non_arrivano-red) | Verifica permessi: **Impostazioni** → Notifiche → TravelCompanion |
| ![Error](https://img.shields.io/badge/❌-AI_non_disponibile-red) | Verifica iOS 26+ e Apple Intelligence abilitata in Impostazioni |
| ![Error](https://img.shields.io/badge/❌-Build_fallisce-red) | Verifica Signing & Capabilities e seleziona un Team valido |
| ![Error](https://img.shields.io/badge/❌-Provisioning_error-red) | Cambia Bundle Identifier in qualcosa di unico |

### Permessi Richiesti

```
📍 Localizzazione (Sempre)     → Per tracking e geofencing
📷 Fotocamera                  → Per scattare foto
🖼️  Libreria Foto              → Per accedere alla galleria
🎤 Microfono                   → Per note vocali
🗣️  Riconoscimento Vocale      → Per trascrizione
🔔 Notifiche                   → Per alert e reminder
```

---

<div align="center">

---

### 📚 Documenti Correlati

| Documento | Descrizione |
|-----------|-------------|
| [README.md](README.md) | Documentazione principale del progetto |
| [VERIFICA_REQUISITI.md](VERIFICA_REQUISITI.md) | Verifica conformità requisiti universitari |


</div>
