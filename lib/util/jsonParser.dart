import 'dart:convert';

import 'package:flutter_ws/model/IndexingInfo.dart';
import 'package:flutter_ws/model/QueryInfo.dart';
import 'package:flutter_ws/model/QueryResult.dart';
import 'package:flutter_ws/model/Video.dart';


class JSONParser {

  static QueryResult parseQueryResult(String rawData){
    String data = JSONParser.trimSocketIoResponseBody(rawData);
    Map parsedMap = JSON.decode(data);

    var resultUnparsed = parsedMap["result"];
    List<dynamic> unparsedResultList = resultUnparsed["results"];
    var unparsedQueryResult = resultUnparsed["queryInfo"];


    QueryInfo queryInfo = new QueryInfo.fromJson(unparsedQueryResult);
    List<Video> videos = unparsedResultList.map((video) => new Video.fromMap(video)).toList();

    QueryResult result = new QueryResult();
    result.queryInfo = queryInfo;
    result.videos = videos;

    return result;
  }

  static String trimSocketIoResponseBody(String rawBody) {
    int startIndex = rawBody.indexOf('{');
    int endEindex = rawBody.lastIndexOf('}');
    String cleanedBody = rawBody.substring(startIndex, endEindex +1);
    return cleanedBody;
}

  static IndexingInfo parseIndexingEvent(String rawData) {

    String data = trimSocketIoResponseBody(rawData);
    Map parsedBody = JSON.decode(data);
    IndexingInfo info = new IndexingInfo.fromJson(parsedBody);

    info.parsingProgress = (info.parserProgress * 100).round();
    info.indexingProgress = (info.indexerProgress * 100).round();

    return info;
  }
}