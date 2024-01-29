import 'package:intl/intl.dart';
import 'package:smartwatch_app/model/stored.dart';

class ReminderEvent implements StoredObject, SharedObject {
  String title;
  String description;
  DateTime date;

  ReminderEvent(
      {required this.title, required this.description, required this.date});

  @override
  String toStorage() =>
      "${title}__v__${description}__v__${DateFormat("yyyy-MM-dd").format(date)}";

  @override
  String serialize() => "$title|${DateFormat("yyyyMMddHHmm").format(date)}00";

  static ReminderEvent? fromStorage(String storageString) {
    List<String> data = storageString.split("__v__");
    try {
      return ReminderEvent(
          title: data[0],
          description: data[1],
          date: DateFormat("yyyy-MM-dd").parse(data[2]));
    } catch (e) {
      return null;
    }
  }
}
