class Calculator{
  static String calculateDuration(duration) {
    try {
      int sekunden = int.parse(duration.toString());
      if (sekunden == 1)
        return "1 sekunde";
      else if (sekunden < 60) return sekunden.toString() + " sekunden";

      int minuten = (sekunden / 60).floor();
      if (minuten < 60) return minuten.toString() + " min";

      int stunden = (minuten / 60).floor();
      int verbleibendeMinuten = minuten % 60;

      return verbleibendeMinuten == 0
          ? stunden.toString() + " h "
          : stunden.toString() +
          " h " +
          verbleibendeMinuten.toString() +
          " min";
    } catch (e) {
      return "";
    }
  }

  static String calculateTimestamp(int timestamp) {
    DateTime time =
    new DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true);
    var minutes =
    time.minute < 9 ? "0" + time.minute.toString() : time.minute.toString();
    var day = time.day < 9 ? "0" + time.day.toString() : time.day.toString();
    var month =
    time.month < 9 ? "0" + time.month.toString() : time.month.toString();

    return day +
        "." +
        month +
        "." +
        time.year.toString() +
        " " +
        time.hour.toString() +
        ":" +
        minutes;
  }
}