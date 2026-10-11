import '../models/audit_question.dart';

const List<AuditQuestion> auditQuestions = [
  AuditQuestion(
    question: 'Hvor ofte drikker du alkohol?',
    answers: [
      'Aldri',
      'Månedlig eller sjeldnere',
      '2–4 ganger i måneden',
      '2–3 ganger i uken',
      '4 eller flere ganger i uken',
    ],
  ),
  AuditQuestion(
    question:
        'Hvor mange alkoholenheter drikker du vanligvis på en dag når du drikker?',
    answers: ['1–2', '3–4', '5–6', '7–9', '10 eller flere'],
  ),
  // AUDIT 3
  // Hyppighet av høyt alkoholinntak (6 eller flere alkoholenheter)

  AuditQuestion(
    question:
        'Hvor ofte drikker du seks alkoholenheter eller mer ved én anledning?',
    answers: [
      'Aldri',
      'Sjeldnere enn én gang i måneden',
      'Hver måned',
      'Hver uke',
      'Daglig eller nesten daglig',
    ],
  ),
  // AUDIT 4
  // Tap av kontroll

  AuditQuestion(
    question:
        'I løpet av det siste året – hvor ofte har du opplevd at det var vanskelig å stoppe å drikke når du først hadde begynt?',
    answers: [
      'Aldri',
      'Sjeldnere enn én gang i måneden',
      'Hver måned',
      'Hver uke',
      'Daglig eller nesten daglig',
    ],
  ),
  // AUDIT 5
  // Forsømmelse av forpliktelser

  AuditQuestion(
    question:
        'I løpet av det siste året – hvor ofte har drikking ført til at du ikke fikk gjort ting som ble forventet av deg?',
    answers: [
      'Aldri',
      'Sjeldnere enn én gang i måneden',
      'Hver måned',
      'Hver uke',
      'Daglig eller nesten daglig',
    ],
  ),
  // AUDIT 6
  // Morgenalkohol (eye opener)

  AuditQuestion(
    question:
        'I løpet av det siste året – hvor ofte har du hatt behov for en alkoholenhet om morgenen for å komme i gang etter å ha drukket dagen før?',
    answers: [
      'Aldri',
      'Sjeldnere enn én gang i måneden',
      'Hver måned',
      'Hver uke',
      'Daglig eller nesten daglig',
    ],
  ),
  // AUDIT 7
  // Skyldfølelse

  AuditQuestion(
    question:
        'I løpet av det siste året – hvor ofte har du kjent skyldfølelse eller hatt dårlig samvittighet på grunn av drikking?',
    answers: [
      'Aldri',
      'Sjeldnere enn én gang i måneden',
      'Hver måned',
      'Hver uke',
      'Daglig eller nesten daglig',
    ],
  ),
  // AUDIT 8
  // Hukommelsestap (blackout)

  AuditQuestion(
    question:
        'I løpet av det siste året – hvor ofte har du opplevd at du ikke kunne huske hva som skjedde kvelden før fordi du hadde drukket alkohol?',
    answers: [
      'Aldri',
      'Sjeldnere enn én gang i måneden',
      'Hver måned',
      'Hver uke',
      'Daglig eller nesten daglig',
    ],
  ),
  // AUDIT 9
  // Alkoholrelatert skade

  AuditQuestion(
    question: 'Har du eller andre blitt skadet som følge av alkoholbruken din?',
    answers: [
      'Nei',
      'Ja, men ikke i løpet av det siste året',
      'Ja, i løpet av det siste året',
    ],
  ),
  // AUDIT 10
  // Bekymring fra andre

  AuditQuestion(
    question:
        'Har en venn, et familiemedlem, en lege eller en annen viktig person vært bekymret for alkoholbruken din, eller foreslått at du bør redusere den?',
    answers: [
      'Nei',
      'Ja, men ikke i løpet av det siste året',
      'Ja, i løpet av det siste året',
    ],
  ),
];
