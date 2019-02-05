import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_ws/enum/ws_event_types.dart';
import 'package:flutter_ws/util/json_parser.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';

class WebsocketHandler {
  static final initializerUrl =
      'https://mediathekviewweb.de/socket.io/?EIO=3&transport=polling&t=M9seBZ1';
  static final websocketRoot =
      'wss://mediathekviewweb.de/socket.io/?EIO=3&transport=websocket&sid=';

  static IOWebSocketChannel createWebsocketChannel(HttpClientResponse response,
      Iterable<Cookie> initialRequestCookies, String sessionId) {
    List<Cookie> responseCookies = response.cookies;
    Cookie uidCookie = initialRequestCookies
        .singleWhere((Cookie cookie) => cookie.name == "uid");
    responseCookies.add(uidCookie);

    //open Websocket channel
    IOWebSocketChannel channel =
        _openWebsocketChannel(sessionId, responseCookies);
    return channel;
  }

  static Future<Map> parseInitialResponseBody(
      HttpClientResponse response) async {
    String body;
    try {
      body = await _readResponse(response);
      print("Received body: " + body.toString());
    } catch (e) {
      print(e);
    }
    String cutBody = JSONParser.trimSocketIoResponseBody(body);
    Map parsedMap = jsonDecode(cutBody);
    return parsedMap;
  }

  static Future<HttpClientResponse> initiallyContactWebsocketEndpoint(
      Iterable<Cookie> cookieList) async {
    //Todo: how to generate the t=M9seBZ1 dynamically?

    var httpClient = new HttpClient();
    var response = await httpClient
        .getUrl(Uri.parse(initializerUrl))
        .then((HttpClientRequest request) {
      List<Cookie> requestCookies = request.cookies;
      requestCookies.addAll(cookieList);
      return request.close();
    });
    return response;
  }

  static Iterable<Cookie> generateInitialRequestCookies() {
    var uuid = new Uuid();
    String id = uuid.v1();
//    String io = "RymH-uAd1DQo_-nTA15Z"; //welches format?
//    Cookie ioCookie = new Cookie("io",  io);
    Cookie idCookie = new Cookie("uid", id);
    return [idCookie];
  }

  static Future<dynamic> _readResponse(HttpClientResponse response) {
    var completer = new Completer();
    var contents = new StringBuffer();
    response.transform(Utf8Decoder()).listen((String data) {
      contents.write(data);
    },
        onError: (error) => print("An error occured reading the response"),
        onDone: () => completer.complete(contents.toString()));
    return completer.future;
  }

  static IOWebSocketChannel _openWebsocketChannel(
      String sessionId, List<Cookie> websocketCookieHeaders) {
    String url = websocketRoot + sessionId;
    print("Using this url to open Socket: " + url);
    Map<String, String> headerMap = new Map<String, String>();
    String cookieValues = websocketCookieHeaders
        .map((cookie) => cookie.name + "=" + cookie.value)
        .join("; ");
    print("Setting cookie header: " + cookieValues);
    headerMap.putIfAbsent("Cookie", () => cookieValues);

    print("Trying to create Websocket Channel");
    IOWebSocketChannel channel = new IOWebSocketChannel.connect(url);
    return channel;
  }

  static String parseSocketIOConnectionType(String data) {
    return WebsocketConnectionTypes.getValues().firstWhere(
        (type) => data.contains(type.toString()),
        orElse: () => WebsocketConnectionTypes.UNKNOWN);
  }
}
