My Recovery Manager Clinical Recommendation Algorithm (MRM-CRA) v1.0

# Bruk av AUDIT i anbefalingsalgoritmen

AUDIT brukes på to nivåer.

## 1. Total AUDIT-skår

Total skår brukes som et mål på samlet risiko knyttet til alkoholbruk.

Skåren alene avgjør ikke om appen anbefaler avhold eller moderasjon.

Den vurderes alltid sammen med øvrige kliniske opplysninger.

## 2. Kliniske nøkkelindikatorer

Enkelte AUDIT-spørsmål vurderes også individuelt fordi de gir viktig klinisk informasjon som ikke nødvendigvis fanges opp av totalskåren.

## AUDIT-spørsmål som vurderes individuelt

Følgende spørsmål inngår som egne kliniske indikatorer i algoritmen:

## Kliniske terskler for AUDIT-nøkkelspørsmål

### AUDIT 4 – Kontrolltap

Registreres som klinisk indikator ved svar:

- Hver måned
- Hver uke
- Daglig eller nesten daglig

Begrunnelse:
Enkeltstående episoder vurderes ikke som tilstrekkelig til å indikere et vedvarende mønster av kontrolltap.

---

### AUDIT 5 – Funksjonssvikt

Registreres som klinisk indikator ved svar:

- Hver måned
- Hver uke
- Daglig eller nesten daglig

Begrunnelse:
Algoritmen skal identifisere et tilbakevendende funksjonsproblem, ikke enkeltstående hendelser.

---

### AUDIT 6 – Morgenalkohol

Registreres som klinisk indikator ved alle positive svar:

- Sjeldnere enn én gang i måneden
- Hver måned
- Hver uke
- Daglig eller nesten daglig

Begrunnelse:
Selv sjeldne episoder med morgenalkohol kan være uttrykk for fysisk avhengighet eller abstinenslindring og tillegges derfor stor klinisk betydning.

---

### AUDIT 8 – Alkoholrelatert hukommelsestap

Registreres som klinisk indikator ved svar:

- Hver måned
- Hver uke
- Daglig eller nesten daglig

Begrunnelse:
Enkeltstående blackouts forekommer også hos personer uten utviklet avhengighet. Algoritmen fokuserer derfor på et tilbakevendende mønster.

---

### AUDIT 9 – Alkoholrelaterte skader

Registreres som klinisk indikator ved svar:

- Ja, i løpet av det siste året

Begrunnelse:
Nylige alkoholrelaterte skader vurderes som mest relevante for anbefalingen.

---

### AUDIT 10 – Bekymring uttrykt av andre

Registreres som klinisk indikator ved svar:

- Ja, i løpet av det siste året

Begrunnelse:
Aktuell bekymring fra familie, venner eller helsepersonell vurderes som mest relevant for dagens situasjon.

## Nære familiemedlemmer med alkoholproblemer

### Klinisk betydning

Alkoholproblemer hos nære familiemedlemmer regnes som en risikofaktor for utvikling og vedlikehold av alkoholproblemer.

Faktoren brukes som støtteinformasjon i algoritmen.

Den fører ikke alene til anbefaling om avhold.

## Psykisk lidelse

### Klinisk betydning

Psykisk lidelse vurderes foreløpig som en moderat risikofaktor.

Den inngår i den samlede kliniske vurderingen, men fører ikke alene til anbefaling om avhold.

### Begrunnelse

Psykiske lidelser varierer betydelig med hensyn til type, alvorlighetsgrad og hvordan de påvirker alkoholbruk og prognose.

I første versjon av algoritmen skilles det derfor ikke mellom ulike diagnoser.

Dette kan vurderes i en senere versjon.

## Tegn på fysisk avhengighet

### Klinisk betydning

Tegn på fysisk avhengighet vurderes som en sterk klinisk indikator.

Forekomst av fysisk avhengighet taler som hovedregel mot et mål om kontrollert alkoholbruk.

### Begrunnelse

Fysisk avhengighet er forbundet med økt risiko for tilbakefall, abstinenssymptomer og komplikasjoner ved fortsatt alkoholbruk.

Algoritmen vil derfor som hovedregel anbefale avhold dersom brukeren oppgir tegn på fysisk avhengighet.

Andre kliniske forhold kan likevel påvirke den samlede vurderingen.

## Sosial støtte

### Klinisk betydning

God sosial støtte vurderes som en beskyttende faktor.

Sosial støtte kan øke sannsynligheten for å lykkes med en endring av alkoholbruken, enten målet er avhold eller moderasjon.

Fravær av sosial støtte fører ikke alene til anbefaling om avhold.

### Begrunnelse

God sosial støtte er assosiert med bedre prognose ved endring av alkoholbruk.

Faktoren brukes derfor som støtteinformasjon i algoritmen.

## Jobb eller utdanning

### Klinisk betydning

Arbeid eller utdanning vurderes som en beskyttende faktor.

Faktoren brukes som støtteinformasjon, men avgjør ikke anbefalingen alene.

### Begrunnelse

Tilknytning til arbeid eller utdanning kan være uttrykk for stabilitet og struktur i hverdagen.

Samtidig finnes det mange personer uten arbeid eller utdanning som lykkes godt med endring av alkoholbruk.

Faktoren tillegges derfor begrenset vekt.

## Tidligere mislykkede forsøk på å redusere eller slutte

### Klinisk betydning

Tidligere mislykkede forsøk vurderes som en sterk klinisk indikator.

Gjentatte mislykkede forsøk på kontrollert alkoholbruk kan tale mot at moderasjon er et realistisk mål.

### Begrunnelse

Tidligere behandlings- og endringsforsøk gir viktig informasjon om prognose og valg av målsetting.

Denne faktoren vurderes alltid sammen med øvrige kliniske opplysninger.

# Mulige anbefalinger

Algoritmen kan gi tre ulike anbefalinger.

## 1. Moderasjon

### Anbefaling

Basert på svarene dine vurderer vi at kontrollert alkoholbruk kan være et realistisk mål dersom du ønsker å endre alkoholbruken.

### Begrunnelse

Anbefalingen bygger på en samlet vurdering av:

- AUDIT
- kliniske indikatorer
- risikofaktorer
- beskyttende faktorer
- motivasjon

### Videre oppfølging

Appen hjelper brukeren med å planlegge og følge opp et mål om moderasjon.

---

## 2. Prøveperiode med avhold

### Anbefaling

Basert på svarene dine er det vanskelig å gi en sikker anbefaling om hvilket mål som vil være mest realistisk for deg.

Vi anbefaler derfor at du vurderer en prøveperiode med avhold, for eksempel i seks måneder. Etter denne perioden kan du ta en ny vurdering av hvilket mål som passer best for deg.

### Begrunnelse

Kartleggingen viser både forhold som taler for moderasjon og forhold som taler for avhold.

En periode uten alkohol kan gi et bedre grunnlag for å vurdere videre målsetting.

### Videre oppfølging

Appen tilpasses som et avholdsprogram i prøveperioden.

Etter seks måneder anbefales ny kartlegging.

---

## 3. Avhold

### Anbefaling

Basert på svarene dine anbefaler vi at målet ditt er avhold fra alkohol.

### Begrunnelse

Anbefalingen bygger på en samlet vurdering av kartleggingen og forhold som tilsier at moderasjon sannsynligvis ikke vil være et trygt eller realistisk mål.

### Videre oppfølging

Appen tilpasses et mål om varig avhold.

# Beslutningstre

## Trinn 1

Foreligger tegn på fysisk avhengighet?

- Ja → gå mot anbefaling om avhold.
- Nei → gå videre.

---

## Trinn 2

Foreligger morgenalkohol (AUDIT 6)?

- Ja → gå mot anbefaling om avhold.
- Nei → gå videre.

---

## Trinn 3

Har brukeren tidligere forsøkt å redusere eller slutte uten å lykkes?

- Ja → registreres som sterk indikator.
- Nei → gå videre.

---

## Trinn 4

Vurder AUDIT-total.

---

## Trinn 5

Vurder øvrige AUDIT-indikatorer.

---

## Trinn 6

Vurder øvrige risikofaktorer.

---

## Trinn 7

Vurder beskyttende faktorer.

---

## Trinn 8

Gi anbefaling.

# Kliniske prinsipper

MRM-CRA bygger på følgende prinsipper:

## 1. Pasientsikkerhet

Ved tvil skal algoritmen velge den anbefalingen som innebærer lavest risiko for brukeren.

## 2. Forklarbarhet

Alle anbefalinger skal kunne begrunnes ut fra brukerens svar.

Algoritmen skal ikke være en "black box".

## 3. Klinisk relevans

Kliniske indikatorer vurderes ut fra deres betydning for valg mellom moderasjon og avhold, ikke bare ut fra deres betydning for diagnostikk.

## 4. Helhetsvurdering

Ingen enkeltfaktor, med unntak av definerte sterke indikatorer, skal alene avgjøre anbefalingen.

## 5. Brukerautonomi

Anbefalingen er beslutningsstøtte.

Brukeren står alltid fritt til å velge et annet mål.

## 6. Revisjon

Algoritmen skal kunne videreutvikles etter hvert som ny forskning, klinisk erfaring og evaluering av appen tilsier det.

# Faglig grunnlag

Denne algoritmen er under utvikling.

Den faglige begrunnelsen for de enkelte beslutningspunktene vil dokumenteres før algoritmen tas i bruk.
Algoritmen er foreløpig basert på klinisk ekspertise fra utvikler som er psykolog med spesialitet i rus- og avhengighet

Aktuelle kilder vil blant annet omfatte:

- Helsedirektoratets anbefalinger
- WHO (AUDIT)
- forskning om moderasjon versus avhold
- forskning om prognostiske faktorer
- forskning om motiverende intervju


# Hvordan MRM vurderer mål for alkoholbruk

Når du bruker MRM til å kartlegge alkoholbruken din, kan appen gi en veiledende anbefaling om hvilket mål som kan være et godt utgangspunkt: moderasjon, en prøveperiode med avhold eller avhold.

Vurderingen gjøres med **MRM-CRA (My Recovery Manager – Clinical Reasoning Approach)**. MRM-CRA er en foreløpig beslutningsmodell utviklet for MRM. Den er ikke et diagnostisk verktøy og er ikke klinisk validert.

## Hva bygger vurderingen på?

MRM-CRA bygger på flere typer informasjon. Modellen legger ikke bare vekt på hvor høy totalskåren på AUDIT er.

### 1. Tegn på mulig fysisk avhengighet

Mulige tegn på fysisk avhengighet har særlig betydning. Dersom svarene tyder på at det kan foreligge fysisk avhengighet, skal dette ikke veies opp mot for eksempel god mestringstro eller god sosial støtte.

MRM kan ikke stille en diagnose på grunnlag av disse svarene. Dersom det kan foreligge fysisk avhengighet, kan det være risiko for abstinens ved brå avslutning av alkoholbruk. Behov for trygg nedtrapping eller annen medisinsk oppfølging må vurderes av helsepersonell. NICE anbefaler at risiko for uplanlagt abstinens og behov for assistert alkoholavvenning inngår i vurderingen av personer med mulig alkoholavhengighet. [1]

### 2. AUDIT

MRM bruker **AUDIT (Alcohol Use Disorders Identification Test)** som en del av kartleggingen.

AUDIT er utviklet av Verdens helseorganisasjon som et screeningsverktøy for å identifisere risikofylt og skadelig alkoholbruk og for å bidra til en videre vurdering. AUDIT kan også bidra til å identifisere tegn på alkoholavhengighet og enkelte konsekvenser av alkoholbruk. [2]

Totalskåren gir et overordnet bilde, men kan ikke alene avgjøre hvilket mål som passer for den enkelte. WHO understreker at grensene for AUDIT-skårer er veiledende, og at klinisk vurdering er nødvendig fordi totalskåren ikke alltid gjenspeiler hele risikobildet. [3]

I MRM-CRA brukes derfor **16 som en øvre grense for grønn anbefaling**. En AUDIT-skår på 16 eller høyere kan ikke alene gi anbefaling om moderasjon.

Dette betyr ikke at en skår på 16 eller høyere automatisk fører til anbefaling om avhold. Høyere skårer gjør at andre forhold i kartleggingen får større betydning.

### 3. Enkelte svar i AUDIT

Totalskåren er ikke det eneste som vurderes. Enkelte spørsmål kan gi viktig informasjon om hvordan alkoholbruken påvirker personen.

MRM-CRA legger særlig merke til:

* vansker med å kontrollere hvor mye man drikker
* problemer eller negative konsekvenser knyttet til alkoholbruken
* alkoholbruk om morgenen
* hukommelsestap eller «blackouts»
* alkoholrelaterte skader
* at andre har uttrykt bekymring for alkoholbruken

Noen av disse forholdene kan ha større betydning for målsettingen enn selve totalskåren. Dette følger prinsippet i AUDIT-materialet om at totalskåren ikke alltid fanger opp hele risikobildet. [3]

### 4. Tidligere forsøk på endring

Tidligere mislykkede forsøk på å redusere eller slutte med alkohol inngår også i vurderingen.

Et tidligere forsøk betyr ikke at moderasjon ikke kan lykkes. Men når en person allerede har forsøkt å endre alkoholbruken uten å lykkes, trekker dette MRM-CRA i retning av å vurdere en periode med avhold.

Tidligere erfaringer med endring og personens egen tro på muligheten for endring er relevante deler av en helhetlig vurdering. NICE anbefaler blant annet at tidligere behandlingsresultater, personens preferanser og tro på egen evne til å endre inngår i planleggingen. [1]

### 5. Andre forhold

MRM-CRA tar også hensyn til enkelte andre forhold som kan påvirke den samlede vurderingen.

Dette kan blant annet være:

* psykiske helseproblemer
* alkoholproblemer i nær familie
* sosial støtte
* arbeid eller utdanning
* mestringstro

Disse faktorene brukes ikke som et poengsystem. De skal bidra til å gi et bredere bilde av situasjonen.

For eksempel kan god sosial støtte og høy mestringstro være beskyttende forhold, mens psykiske helseproblemer eller flere samtidige risikofaktorer kan gjøre det mer aktuelt å vurdere avhold.

## Tre mulige anbefalinger

MRM-CRA kan gi tre ulike anbefalinger:

### Moderasjon kan være et realistisk mål

Dette er den grønne kategorien.

Den brukes når kartleggingen ikke viser forhold som gjør at MRM-CRA bør anbefale avhold, og AUDIT-skåren er under 16.

Anbefalingen betyr ikke at moderasjon vil fungere for deg. Den betyr at kontrollert alkoholbruk kan være et realistisk mål ut fra opplysningene du har gitt.

### Prøveperiode med avhold

Dette er den gule kategorien.

Den brukes når risikobildet er mer sammensatt eller usikkert, og hvor en periode med avhold kan gi et bedre grunnlag for å vurdere hva som fungerer videre.

En prøveperiode med avhold er ikke nødvendigvis ment som en permanent beslutning. Etter perioden kan målet vurderes på nytt.

### Avhold

Dette er den røde kategorien.

Den brukes når kartleggingen viser et tydeligere risikobilde, for eksempel mulige tegn på fysisk avhengighet eller en kombinasjon av flere betydelige risikofaktorer.

En slik anbefaling betyr at MRM-CRA vurderer avhold som det mest hensiktsmessige utgangspunktet basert på svarene som er gitt.

## MRM bestemmer ikke målet ditt

MRM-CRA gir en **veiledende anbefaling**. Du bestemmer selv hvilket mål du ønsker å sette.

Det betyr at du kan velge moderasjon selv om MRM anbefaler avhold, eller velge avhold selv om MRM vurderer moderasjon som et mulig mål.

Dette er et bevisst prinsipp i MRM. Målsetting bør ta hensyn til personens egne ønsker, verdier og forutsetninger. NICE anbefaler også at behandlingsmål avtales sammen med personen, og at personens preferanser inngår i vurderingen. [1]

## Hva MRM-CRA ikke gjør

MRM-CRA:

* stiller ikke diagnose
* avgjør ikke om du er alkoholavhengig
* erstatter ikke en medisinsk eller psykologisk vurdering
* kan ikke forutsi sikkert hvilket mål som vil lykkes
* bruker ikke en enkel poengsum for å avgjøre målet ditt
* er ikke en klinisk validert beslutningsalgoritme

Modellen er utviklet for å gjøre MRM sin målsettingsprosess mer strukturert og transparent. Den bygger på faglige kilder om alkoholbruk, screening, risikovurdering og målsetting, men selve MRM-CRA-modellen er MRM sitt eget produktvalg.

## Hvis du velger avhold

Hvis du velger avhold, vil MRM også gi viktig informasjon om risikoen ved å slutte brått dersom det kan foreligge fysisk avhengighet.

Dersom du drikker mye eller regelmessig og kan være fysisk avhengig, bør du ikke anta at det er trygt å slutte brått uten å vurdere behovet for medisinsk hjelp. Risiko ved abstinens og behov for assistert avvenning er en del av den kliniske risikovurderingen ved alkoholproblemer. [1]

Ved usikkerhet bør du kontakte lege eller annen relevant helsetjeneste.

## Kunnskapsgrunnlaget

MRM-CRA bygger blant annet på Verdens helseorganisasjons materiale om AUDIT og screening av alkoholbruk, samt kliniske retningslinjer fra NICE om vurdering og behandling av alkoholproblemer.

Det er viktig å skille mellom **kunnskapsgrunnlaget for de enkelte metodene og faktorene** og dokumentasjon av selve MRM-CRA. AUDIT er et etablert screeningsverktøy, mens MRM-CRA er en foreløpig modell utviklet for MRM og er ikke klinisk validert.

### Referanser

**[1] NICE.** *Alcohol-use disorders: diagnosis, assessment and management of harmful drinking (high-risk drinking) and alcohol dependence (CG115).* Anbefalinger om vurdering, behandlingsmål, AUDIT, avhengighet, psykiske helseproblemer og risiko ved abstinens.
[NICE – CG115 Recommendations](https://www.nice.org.uk/guidance/cg115/chapter/Recommendations)

**[2] World Health Organization (WHO).** *AUDIT: The Alcohol Use Disorders Identification Test – Guidelines for Use in Primary Health Care.* WHO/MSD/MSB/01.6a.
[WHO – AUDIT Guidelines](https://www.who.int/publications/i/item/WHO-MSD-MSB-01.6a?utm_source=chatgpt.com)

**[3] World Health Organization (WHO).** *Brief Intervention for Hazardous and Harmful Drinking: A Manual for Use in Primary Care.* WHO/MSD/MSB/01.6b. Beskriver AUDIT-soner og understreker at skårgrenser er veiledende og må tolkes i sammenheng med det øvrige risikobildet.
[WHO – Brief Intervention for Hazardous and Harmful Drinking](https://www.who.int/docs/default-source/substance-use/who-msd-msb-01-6b.pdf?utm_source=chatgpt.com)
