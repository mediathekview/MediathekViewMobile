//enum WebsocketConnectionTypes{
//
//  indexState, uid, connect, disconnect, result, unknown
//  //indexState, uid, connect, disconnect, probe, probeAnswer, ping, pong, queryEntries, result, unknown
//}

class WebsocketConnectionTypes {
  static final String INDEX_STATE = "indexState";
  static final String UID = "uid";
  static final String CONNECT = "connect";
  static final String DISCONNECT = "disconnect";
  static final String RESULT = "result";
  static final String UNKNOWN = "unknown";

  static Iterable<String> getValues() {
    return [RESULT, INDEX_STATE, UID, CONNECT, DISCONNECT, UNKNOWN];
  }
}
