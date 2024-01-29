import 'package:smartwatch_app/model/stored.dart';

class Alarm implements StoredObject, SharedObject {
  int hour;
  int minute;

  Alarm({required this.hour, required this.minute});

  @override
  String toStorage() =>
      "${hour.toString().padLeft(2, '0')}__v__${minute.toString().padLeft(2, '0')}";

  static Alarm? fromStorage(String storageString) {
    List<String> data = storageString.split("__v__");
    try {
      return Alarm(hour: int.parse(data[0]), minute: int.parse(data[1]));
    } catch (e) {
      return null;
    }
  }

  @override
  String serialize() =>
      "${hour.toString().padLeft(2, '0')}${minute.toString().padLeft(2, '0')}";

}
