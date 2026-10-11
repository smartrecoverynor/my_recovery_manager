DateTime getAppDate(DateTime dateTime) {
  if (dateTime.hour < 7) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day - 1);
  }

  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}
