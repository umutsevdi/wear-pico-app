import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartwatch_app/model/configuration.dart';
import 'package:smartwatch_app/model/steps.dart';

import '../model/alarm.dart';
import '../model/event.dart';
import '../model/stored.dart';

class StorageController extends GetxController {
  static SharedPreferences? _preferences;

  late CrudOperator<Alarm> alarmOperator;
  late CrudOperator<ReminderEvent> eventOperator;
  late CrudOperator<Steps> stepOperator;
  late CrudOperator<Configuration> configOperator;

  final RxList<Alarm> _alarms = <Alarm>[].obs;
  final RxList<ReminderEvent> _events = <ReminderEvent>[].obs;
  final RxList<Steps> _steps = <Steps>[].obs;
  final RxList<Configuration> _config = <Configuration>[].obs;

  List<Alarm> get alarms => _alarms;

  List<ReminderEvent> get events => _events;

  List<Steps> get steps => _steps;

  List<Configuration> get config => _config;

  @override
  void onInit() async {
    _preferences ??= await SharedPreferences.getInstance();
    alarmOperator = CrudOperator(
        key: "alarms",
        preferences: _preferences!,
        items: _alarms,
        comparator: (a, b) =>
            (a.hour * 24 + a.minute).compareTo(b.hour * 24 + b.minute));
    eventOperator = CrudOperator(
        key: "events",
        preferences: _preferences!,
        items: _events,
        comparator: (a, b) => a.date.compareTo(b.date));
    stepOperator = CrudOperator(
        key: "steps",
        preferences: _preferences!,
        items: _steps,
        comparator: (a, b) => a.date.compareTo(b.date));
    configOperator = CrudOperator<Configuration>(
        key: "config",
        preferences: _preferences!,
        items: _config,
        comparator: (a, b) => 0);

    List<String>? alarms = _preferences!.getStringList("alarms");
    if (alarms != null) {
      _alarms.value = alarms.map((e) => Alarm.fromStorage(e)).nonNulls.toList();
    }
    List<String>? events = _preferences!.getStringList("events");
    if (events != null) {
      _events.value =
          events.map((e) => ReminderEvent.fromStorage(e)).nonNulls.toList();
    }
    List<String>? newSteps = _preferences!.getStringList("steps");
    if (newSteps != null) {
      _steps.value =
          newSteps.map((entry) => Steps.fromStorage(entry)).nonNulls.toList();
    }
    List<String>? newConfig = _preferences!.getStringList("config");
    _config.value = newConfig != null && newConfig.isNotEmpty
        ? newConfig.map((e) => Configuration.fromStorage(e)).nonNulls.toList()
        : <Configuration>[Configuration()];
    super.onInit();
  }
}

/// Generic class for the read, update delete events on the SharedPreferences
class CrudOperator<T extends StoredObject> {
  final String key;
  final RxList<T> items;
  SharedPreferences preferences;
  Comparator<T> comparator;

  CrudOperator(
      {required this.key,
      required this.preferences,
      required this.items,
      required this.comparator});

  /// Inserts [item] to the SharedPreferences
  ///
  /// [returns] the updated list
  Future<List<T>> add(T item) async {
    items.add(item);
    items.sort(comparator);
    await _save();
    return items;
  }

  /// Replaces the item at the [index] index with the [item]
  ///
  /// [returns] the updated list
  Future<List<T>> update(int index, T item) async {
    items[index] = item;
    items.sort(comparator);
    await _save();
    return items;
  }

  /// Deletes the item at the [index]
  ///
  /// [returns] the updated list
  Future<List<T>> delete(int index) async {
    items.removeAt(index);
    await _save();
    return items;
  }

  /// Underlying update function
  Future<void> _save() async {
    preferences.setStringList(key, items.map((e) => e.toStorage()).toList());
  }
}
