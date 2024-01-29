import 'package:intl/intl.dart';
import 'package:smartwatch_app/model/stored.dart';

class Steps implements StoredObject, SharedObject {
  DateTime date;
  int steps;

  Steps({required this.date, required this.steps});

  @override
  String toStorage() => "${DateFormat("yyyy-MM-dd").format(date)}__v__$steps";

  @override
  String serialize() => "$steps";

  static Steps? deserialize(DateTime date, String string) {
    try {
      return Steps(date: date, steps: int.parse(string));
    } catch (e) {
      return null;
    }
  }

  static Steps? fromStorage(String storageString) {
    List<String> data = storageString.split("__v__");
    try {
      return Steps(
          date: DateFormat("yyyy-MM-dd").parse(data[0]),
          steps: int.parse(data[1]));
    } catch (e) {
      return null;
    }
  }
}
