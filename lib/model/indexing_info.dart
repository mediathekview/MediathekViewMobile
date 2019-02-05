class IndexingInfo {
  var entries; //Todo: determine what entries are & choose apropriate type
  String time;
  bool error;
  bool done;
  double parserProgress;
  double indexerProgress;
  int parsingProgress;
  int indexingProgress;

  IndexingInfo();

  IndexingInfo.fromJson(Map<String, dynamic> json)
      : entries = json['entries'],
        time = json['time'],
        error = json['error'],
        done = json['done'],
        parserProgress = json['parserProgress'],
        indexerProgress = json['indexingProgress'];
}