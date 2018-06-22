class QueryInfo {
  String filmlisteTimestamp;
  String searchEngineTime;
  int resultCount;
  int totalResults;

  QueryInfo(this.filmlisteTimestamp, this.searchEngineTime, this.resultCount, this.totalResults);

  QueryInfo.fromJson(Map<String, dynamic> json)
      : filmlisteTimestamp = json['filmlisteTimestamp'],
        searchEngineTime = json['searchEngineTime'],
        resultCount = json['resultCount'],
        totalResults = json['totalResults'];
}