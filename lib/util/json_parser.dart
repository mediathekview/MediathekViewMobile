import 'dart:convert';

import 'package:flutter_ws/model/indexing_info.dart';
import 'package:flutter_ws/model/query_info.dart';
import 'package:flutter_ws/model/query_result.dart';
import 'package:flutter_ws/model/video.dart';

class JSONParser {
  static QueryResult parseQueryResult(String rawData) {
    Map parsedMap = jsonDecode(rawData);

    var resultUnparsed = parsedMap["result"];
    List<dynamic> unparsedResultList = resultUnparsed["results"];
    var unparsedQueryResult = resultUnparsed["queryInfo"];

    QueryInfo queryInfo = new QueryInfo.fromJson(unparsedQueryResult);
    List<Video> videos =
        unparsedResultList.map((video) => new Video.fromMap(video)).toList();

    QueryResult result = new QueryResult();
    result.queryInfo = queryInfo;
    result.videos = videos;

    return result;
  }

  static IndexingInfo parseIndexingEvent(String rawData) {
    Map parsedBody = jsonDecode(rawData);
    IndexingInfo info = new IndexingInfo.fromJson(parsedBody);

    info.parsingProgress = (info.parserProgress * 100).round();
    info.indexingProgress = (info.indexerProgress * 100).round();

    return info;
  }
}
