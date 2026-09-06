import '../models/recommendation_factor.dart';

final List<RecommendationFactor> recommendationFactors = [
  RecommendationFactor(
    title: 'Jeg har nære familiemedlemmer med alkoholproblemer.',
  ),

  RecommendationFactor(
    title: 'Jeg har en psykisk lidelse.',
  ),

  RecommendationFactor(
    title: 'Jeg har opplevd tegn på fysisk avhengighet.',
    infoTitle: 'Hva menes med fysisk avhengighet?',
    infoMessage:
    'Tegn på fysisk avhengighet kan være at du får skjelvinger, svetting, uro, kvalme eller andre abstinenssymptomer når alkoholen går ut av kroppen. Mange opplever at symptomene blir mindre når de drikker alkohol igjen.',
  ),

  RecommendationFactor(
    title:
    'Jeg har personer rundt meg som støtter meg i å endre alkoholbruken.',
  ),

  RecommendationFactor(
    title: 'Jeg er i jobb eller utdanning.',
  ),

  RecommendationFactor(
    title:
    'Jeg har tidligere forsøkt å redusere eller slutte å drikke uten å lykkes.',
  ),
];