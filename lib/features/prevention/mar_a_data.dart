class MarAQuestion {
  final int number;
  final String text;
  final String subscale;

  const MarAQuestion({
    required this.number,
    required this.text,
    required this.subscale,
  });
}

const marAQuestions = <MarAQuestion>[
  MarAQuestion(
    number: 1,
    text: 'Hvis jeg var generelt deprimert',
    subscale: 'Negativ emosjonell tilstand',
  ),
  MarAQuestion(
    number: 2,
    text: 'Hvis jeg følte meg urolig, uvel eller kvalm',
    subscale: 'Negativ fysisk tilstand',
  ),
  MarAQuestion(
    number: 3,
    text: 'Hvis jeg var glad',
    subscale: 'Positiv emosjonell tilstand',
  ),
  MarAQuestion(
    number: 4,
    text: 'Hvis jeg følte at jeg var uten muligheter for hjelp og støtte',
    subscale: 'Negativ emosjonell tilstand',
  ),
  MarAQuestion(
    number: 5,
    text: 'Hvis jeg ville se om jeg kunne klare et moderat forbruk av alkohol',
    subscale: 'Teste personlig kontroll',
  ),
  MarAQuestion(
    number: 6,
    text:
        'Hvis jeg var et sted der jeg hadde brukt eller kjøpt drikkevarer tidligere',
    subscale: 'Sug og fristelser',
  ),
  MarAQuestion(
    number: 7,
    text: 'Hvis jeg følte meg spent eller nervøs i samvær med en annen',
    subscale: 'Konflikter med andre',
  ),
  MarAQuestion(
    number: 8,
    text:
        'Hvis jeg ble invitert hjem til noen, ble tilbudt alkohol og følte det var vanskelig å si nei',
    subscale: 'Opplevd press fra andre',
  ),
  MarAQuestion(
    number: 9,
    text: 'Hvis jeg møtte gamle venner, og vi ønsket å ha det hyggelig sammen',
    subscale: 'Positive sosiale situasjoner',
  ),
  MarAQuestion(
    number: 10,
    text: 'Hvis jeg ikke klarte å uttrykke følelsene mine overfor en person',
    subscale: 'Konflikter med andre',
  ),
  MarAQuestion(
    number: 11,
    text: 'Hvis jeg følte at jeg hadde skuffet meg selv',
    subscale: 'Negativ emosjonell tilstand',
  ),
  MarAQuestion(
    number: 12,
    text: 'Hvis jeg hadde problemer med å sove',
    subscale: 'Negativ fysisk tilstand',
  ),
  MarAQuestion(
    number: 13,
    text: 'Hvis jeg følte meg trygg og avslappet',
    subscale: 'Positiv emosjonell tilstand',
  ),
  MarAQuestion(
    number: 14,
    text: 'Hvis jeg kjedet meg',
    subscale: 'Negativ emosjonell tilstand',
  ),
  MarAQuestion(
    number: 15,
    text:
        'Hvis jeg ville bevise for meg selv at drikkingen ikke var et problem for meg',
    subscale: 'Teste personlig kontroll',
  ),
  MarAQuestion(
    number: 16,
    text:
        'Hvis jeg uventet kom over alkohol eller så noe som minnet meg om alkohol/drikking',
    subscale: 'Sug og fristelser',
  ),
  MarAQuestion(
    number: 17,
    text: 'Hvis andre tok avstand fra meg eller så ut som om de ikke likte meg',
    subscale: 'Konflikter med andre',
  ),
  MarAQuestion(
    number: 18,
    text:
        'Hvis jeg var ute med venner, som stadig foreslo at vi skulle gå et sted og drikke',
    subscale: 'Opplevd press fra andre',
  ),
  MarAQuestion(
    number: 19,
    text:
        'Hvis jeg var sammen med en nær venn, og vi ønsket å føle oss enda nærmere hverandre',
    subscale: 'Positive sosiale situasjoner',
  ),
  MarAQuestion(
    number: 20,
    text:
        'Hvis noen behandlet meg urettferdig eller blandet seg borti mine planer',
    subscale: 'Konflikter med andre',
  ),
  MarAQuestion(
    number: 21,
    text: 'Hvis jeg følte meg ensom',
    subscale: 'Negativ emosjonell tilstand',
  ),
  MarAQuestion(
    number: 22,
    text: 'Hvis jeg ønsket å være våken, mer oppmerksom eller energisk',
    subscale: 'Negativ fysisk tilstand',
  ),
  MarAQuestion(
    number: 23,
    text: 'Hvis jeg følte meg oppglødd over noe',
    subscale: 'Positiv emosjonell tilstand',
  ),
  MarAQuestion(
    number: 24,
    text: 'Hvis jeg var engstelig og spent for noe',
    subscale: 'Negativ emosjonell tilstand',
  ),
  MarAQuestion(
    number: 25,
    text:
        'Hvis jeg ville finne ut om jeg kunne drikke en gang iblant uten å bli avhengig',
    subscale: 'Teste personlig kontroll',
  ),
  MarAQuestion(
    number: 26,
    text: 'Hvis jeg hadde brukt stoff, og tenkte på å drikke alkohol',
    subscale: 'Sug og fristelser',
  ),
  MarAQuestion(
    number: 27,
    text:
        'Hvis jeg følte et sterkt press og store forventninger fra min familie eller at jeg ikke kunne leve opp til familiens forventninger',
    subscale: 'Konflikter med andre',
  ),
  MarAQuestion(
    number: 28,
    text:
        'Hvis andre i samme rom drakk alkohol, og jeg følte en forventning om å gjøre det samme',
    subscale: 'Opplevd press fra andre',
  ),
  MarAQuestion(
    number: 29,
    text: 'Hvis jeg var sammen med venner og ønsket å ha det enda mer hyggelig',
    subscale: 'Positive sosiale situasjoner',
  ),
  MarAQuestion(
    number: 30,
    text:
        'Hvis jeg ikke hadde et bra forhold til andre på skolen, arbeid eller andre steder',
    subscale: 'Konflikter med andre',
  ),
  MarAQuestion(
    number: 31,
    text: 'Hvis jeg fikk skyldfølelse for noe',
    subscale: 'Negativ emosjonell tilstand',
  ),
  MarAQuestion(
    number: 32,
    text: 'Hvis jeg ønsket å redusere vekten min',
    subscale: 'Negativ fysisk tilstand',
  ),
  MarAQuestion(
    number: 33,
    text: 'Hvis jeg var fornøyd med livet',
    subscale: 'Positiv emosjonell tilstand',
  ),
  MarAQuestion(
    number: 34,
    text: 'Hvis jeg følte meg overveldet og ønsket å flykte',
    subscale: 'Negativ emosjonell tilstand',
  ),
  MarAQuestion(
    number: 35,
    text:
        'Hvis jeg ønsket å teste om jeg kunne klare å være sammen med venner som drakk selv uten å drikke',
    subscale: 'Teste personlig kontroll',
  ),
  MarAQuestion(
    number: 36,
    text: 'Hvis jeg hørte noen snakke om deres tidligere erfaring med drikking',
    subscale: 'Sug og fristelser',
  ),
  MarAQuestion(
    number: 37,
    text: 'Hvis det var krangel og spetakkel hjemme',
    subscale: 'Konflikter med andre',
  ),
  MarAQuestion(
    number: 38,
    text:
        'Hvis jeg ble «presset» til å drikke alkohol og følte at jeg ikke kunne si nei',
    subscale: 'Opplevd press fra andre',
  ),
  MarAQuestion(
    number: 39,
    text: 'Hvis jeg ønsket å feire noe sammen med en venn',
    subscale: 'Positive sosiale situasjoner',
  ),
  MarAQuestion(
    number: 40,
    text:
        'Hvis noen var misfornøyd med jobben min, eller jeg følte meg under sterkt press på jobben, skolen eller andre steder',
    subscale: 'Konflikter med andre',
  ),
  MarAQuestion(
    number: 41,
    text: 'Hvis jeg ble sint over noe som hadde hendt',
    subscale: 'Negativ emosjonell tilstand',
  ),
  MarAQuestion(
    number: 42,
    text: 'Hvis jeg hadde hodepine, eller hadde kroppslige smerter',
    subscale: 'Negativ fysisk tilstand',
  ),
  MarAQuestion(
    number: 43,
    text: 'Hvis jeg husket noe positivt som hadde hendt',
    subscale: 'Positiv emosjonell tilstand',
  ),
  MarAQuestion(
    number: 44,
    text: 'Hvis jeg var forvirret og usikker på hva jeg skulle gjøre',
    subscale: 'Negativ emosjonell tilstand',
  ),
  MarAQuestion(
    number: 45,
    text:
        'Hvis jeg ønsket å teste ut om jeg kunne klare å være i «drikkemiljøet» uten at jeg selv brukte alkohol',
    subscale: 'Teste personlig kontroll',
  ),
  MarAQuestion(
    number: 46,
    text: 'Hvis jeg begynte å tenke på en god rusopplevelse',
    subscale: 'Sug og fristelser',
  ),
  MarAQuestion(
    number: 47,
    text: 'Hvis jeg kunne trenge mot og styrke i forhold til en annen',
    subscale: 'Konflikter med andre',
  ),
  MarAQuestion(
    number: 48,
    text: 'Hvis jeg var sammen med en gruppe mennesker der alle drakk alkohol',
    subscale: 'Opplevd press fra andre',
  ),
  MarAQuestion(
    number: 49,
    text: 'Hvis jeg hadde en fin stund og ville øke min seksuelle glede',
    subscale: 'Positive sosiale situasjoner',
  ),
  MarAQuestion(
    number: 50,
    text:
        'Hvis jeg følte at noen prøvde å kontrollere meg, og jeg ønsket å være mer uavhengig',
    subscale: 'Konflikter med andre',
  ),
];
