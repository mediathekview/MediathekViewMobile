import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ws/exceptions/failed_to_contact_websocket.dart';
import 'package:flutter_ws/websocket/websocket.dart';
import 'package:flutter_ws/widgets/filterMenu/search_filter.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebsocketController {
  final Logger logger = new Logger('WebsocketController');
  static WebSocketChannel wsChannel;

  //callbacks
  var onDataReceived;
  var onError;
  var onDone;
  var onWebsocketChannelOpenedSuccessfully;

  static Timer continoousPingTimer;
  ConnectionState connectionState = ConnectionState.none;

  WebsocketController(
      {@required this.onDataReceived,
      @required this.onDone,
      @required this.onWebsocketChannelOpenedSuccessfully,
      @required this.onError});

  Future<bool> initializeWebsocket() async {
    if (connectionState == ConnectionState.active) {
      logger.fine("Not re-initializing of Websocket - current is still active");
    }

    //setting null to garbage collect
    wsChannel = null;

    Iterable<Cookie> initialRequestCookies =
        WebsocketHandler.generateInitialRequestCookies();

    logger.fine("Initially contacting Websocket Endpoint");
    HttpClientResponse response;
    try {
      response = await WebsocketHandler.initiallyContactWebsocketEndpoint(
          initialRequestCookies);
    } catch (e) {
      onError(new FailedToContactWebsocketError(e.toString()));
      return false;
    }

    if (response == null || response.statusCode == null) {
      onError(new FailedToContactWebsocketError(
          "Failed to retrieve valid session id from websocket endpoint"));
      return false;
    }

    if (response.statusCode != HttpStatus.OK) {
      logger.severe(
          'Error getting sessionId address:\nHttp status ${response.statusCode}');
      onError(new FailedToContactWebsocketError(
          "Failed to retrieve valid session id from websocket endpoint"));
      return false;
    }

    logger.fine("Recieved OK when initially contacting the Websocket Endpoint");
    Map parsedMap = await WebsocketHandler.parseInitialResponseBody(response);

    String sessionId = parsedMap["sid"];
    int pingInterval = parsedMap["pingInterval"];
    //TODO not in use currently
    int pingTimeout = parsedMap["pingTimeout"];

    logger.fine("Extracted session ID: " +
        sessionId +
        " ping Timeout: " +
        pingTimeout.toString() +
        " ping interval " +
        pingInterval.toString());

    try {
      wsChannel = WebsocketHandler.createWebsocketChannel(
          response, initialRequestCookies, sessionId);

      logger.fine('Received websocket Channel');
      onWebsocketChannelOpenedSuccessfully();
    } catch (e) {
      logger.severe("Error connecting to websocket" + e.toString());
      onError(new FailedToContactWebsocketError(e.toString()));
      return false;
    }

    listenToWebsocket();

    //start handshake
    sendSocketStartingSequence();

    logger.fine("Sending ping during ws init");
    wsChannel.sink.add("2");

    //Socket IO hearthbeat
    sendContinoousPing(pingInterval - pingTimeout);

    return true;
  }

  void sendSocketStartingSequence() {
    logger.fine("Sending Socket IO initializing sequence");
    wsChannel.sink.add("2probe");
    wsChannel.sink.add("5");
  }

  void sendContinoousPing(int websocketHearthbeatInterval) {
    if (continoousPingTimer == null || !continoousPingTimer.isActive) {
      Duration duration = new Duration(milliseconds: 2000);
      logger.fine("Starting ping with interval of " +
          websocketHearthbeatInterval.toString() +
          " milliseconds");
      continoousPingTimer = new Timer.periodic(
        duration,
        (Timer t) {
          if (wsChannel == null) {
            logger.fine("ping NOT send. Channel => null");
            return;
          } else if (connectionState != ConnectionState.active) {
            logger.fine("ping NOT send. Connection State: " +
                connectionState.toString());
            logger.fine("Channel used: " + wsChannel.hashCode.toString());
            return;
          }
          logger.fine("Channel used: " + wsChannel.hashCode.toString());
          logger.fine("Sending regular ping");
          wsChannel.sink.add("2");
        },
      );
    }
  }

  void listenToWebsocket() {
    logger.fine("Started listening to Websocket...");
    wsChannel.stream.listen((data) {
      connectionState = ConnectionState.active;
      onDataReceived(data);
    }, onError: (error) {
      connectionState = ConnectionState.done;
      onError(new FailedToContactWebsocketError(error.toString()));
    }, onDone: () {
      connectionState = ConnectionState.done;
      onDone();
    });
  }

  //TODO add search model
  void queryEntries(String genericQuery,
      Map<String, SearchFilter> searchFilters, int skip, int amount) {
    List<String> queryFilters = new List();

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

    String request = '4211["queryEntries",{"queries":[' +
        queryFilters.join(',') +
        '],"sortBy":"timestamp","sortOrder":"desc","future":false,"offset":' +
        skip.toString() +
        ',"size":' +
        amount.toString() +
        '}]';

    logger.fine("Firing request: " +
        request +
        "With connection state: " +
        connectionState.toString());
    if (wsChannel != null) {
      wsChannel.sink.add(request);
    } else {
      logger.severe("Trying to query entries but channel is null");
    }
  }

  void stopPing() {
    if (continoousPingTimer != null && continoousPingTimer.isActive)
      continoousPingTimer.cancel();
  }

  void closeWebsocketChannel() {
    if (wsChannel != null) wsChannel.sink.close();
  }
}
