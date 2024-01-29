// ignore_for_file: constant_identifier_names

enum RequestType {
  CALL_BEGIN(id: 0), // Call start event. Payload: "Caller"
  CALL_END(id: 1), // Occurs when the Call event is handled by the phone.
  NOTIFY(
      id: 2), // Notification event. Triggers an interrupt. Payload: Title|Message
  REMINDER(id: 3),
  OSC(id: 4), // On Song Change Event. Payload: "Song|Album|Artist"
  FETCH_DATE(id: 5), // Update request. Payload: "{DateTime}"
  FETCH_ALARM(id: 6),
  STEP(id: 7), // Step count event. Payload: "StepCount"
  HB(id: 8), // Heartbeat request to show Pico connection is alive
  CONFIG(id: 9); // Fetch configurations

  final int id;

  const RequestType({required this.id});

  String prepareMessage(List<Object>? args) {
    String message = "$id|";
    for (Object arg in args ?? []) {
      message += "$arg|";
    }
    return "$message\r\n";
  }

  static RequestType? of(int id) {
    for (RequestType t in RequestType.values) {
      if (t.id == id) {
        return t;
      }
    }
    return null;
  }
}

enum ResponseType {
  OK(id: 0),
  ERR(id: 1),
  CALL_OK(id: 2),
  CALL_CANCEL(id: 3),
  OSC_PREV(id: 4),
  OSC_PLAY_PAUSE(id: 5),
  OSC_NEXT(id: 6),
  STEP(id: 7);

  final int id;

  const ResponseType({required this.id});

  static ResponseType? of(int id) {
    for (ResponseType t in ResponseType.values) {
      if (t.id == id) {
        return t;
      }
    }
    return null;
  }

  static MapEntry<ResponseType, int?>? parse(String message) {
    List<String> tokens = message.split("|");
    if (tokens.length > 3 || tokens.isEmpty) {
      return null;
    }
    try {
      int id = int.parse(tokens[0]);
      ResponseType? type = ResponseType.of(id);
      if (type != ResponseType.STEP) {
        return MapEntry<ResponseType, int?>(type!, null);
      } else {
        return MapEntry(type!, int.parse(tokens[1]));
      }
    } on FormatException catch (_) {
      return null;
    }
  }
}
