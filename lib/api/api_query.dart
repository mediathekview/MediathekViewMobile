import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ws/widgets/filterMenu/search_filter.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

class APIQuery {
  final Logger logger = new Logger('WebsocketController');

  //callbacks
  var onDataReceived;
  var onError;

  static int skip = 0;
  static final int defaultQueryAmount = 60;

  static Timer continoousPingTimer;
  ConnectionState connectionState = ConnectionState.none;

  APIQuery({@required this.onDataReceived, @required this.onError});

  void search(String genericQuery, Map<String, SearchFilter> searchFilters) {
    List<String> queryFilters = new List();

    logger.info("Query skip: " + skip.toString());

    if (searchFilters.containsKey('Titel') &&
        searchFilters['Titel'].filterValue.isNotEmpty)
      queryFilters.add('{"fields":["title"],"query":"' +
          searchFilters['Titel'].filterValue.toLowerCase() +
          '"}');

    if (searchFilters.containsKey('Thema') &&
        searchFilters['Thema'].filterValue.isNotEmpty &&
        genericQuery != null &&
        genericQuery.isNotEmpty) {
      //generics -> title only
      queryFilters.add(
          '{"fields":["title"],"query":"' + genericQuery.toLowerCase() + '"}');
    } else if (genericQuery != null && genericQuery.isNotEmpty)
      queryFilters.add('{"fields":["topic","title"],"query":"' +
          genericQuery.toLowerCase() +
          '"}');

    if (searchFilters.containsKey('Thema') &&
        searchFilters['Thema'].filterValue.isNotEmpty)
      queryFilters.add('{"fields":["topic"],"query":"' +
          searchFilters['Thema'].filterValue.toLowerCase() +
          '"}');

    if (searchFilters.containsKey('Sender'))
      searchFilters['Sender'].filterValue.split(";").forEach((channel) =>
          queryFilters.add('{"fields":["channel"],"query":"' +
              channel.toLowerCase() +
              '"}'));

    String request = '{"queries":[' +
        queryFilters.join(',') +
        '],"sortBy":"timestamp","sortOrder":"desc","future":false,"offset":' +
        skip.toString() +
        ',"size":' +
        defaultQueryAmount.toString() +
        '}';

    logger.info("Firing request: " + request);

    execute(request);

    skip = skip + defaultQueryAmount;
  }

  void resetSkip() {
    skip = 0;
  }

  int getCurrentSkip() {
    return skip;
  }

  void execute(String query) {
    http
        .post(
          'https://mediathekviewweb.de/api/query',
          body: query,
        )
        .catchError((err) => onError(err))
        .then((value) {
      if (value != null) {
        //logger.info("Response: " + value.body);
        onDataReceived(value.body.toString());
      }
    });
  }
}
