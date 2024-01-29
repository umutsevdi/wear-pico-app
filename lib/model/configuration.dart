import 'package:smartwatch_app/model/stored.dart';

class Configuration implements SharedObject, StoredObject {
  static const int DEV_NONE = 0;
  static const int DEV_BUZZER = 1;
  static const int DEV_LED = 2;
  static const int DEV_VIB = 4;

  int brightness;
  int alarmFlag;
  int callFlag;
  int notifyFlag;
  int reminderFlag;

  Configuration(
      {this.brightness = 100,
      this.alarmFlag = DEV_BUZZER | DEV_LED,
      this.callFlag = DEV_BUZZER | DEV_LED | DEV_VIB,
      this.notifyFlag = DEV_BUZZER | DEV_VIB,
      this.reminderFlag = DEV_BUZZER | DEV_VIB});

  @override
  String serialize() => "${brightness.toString().padLeft(3, '0')}|"
      "${alarmFlag.toString().padLeft(2, '0')}|"
      "${callFlag.toString().padLeft(2, '0')}|"
      "${notifyFlag.toString().padLeft(2, '0')}|"
      "${reminderFlag.toString().padLeft(2, '0')}";

  @override
  String toStorage() => "${brightness.toString().padLeft(3, '0')}|"
      "${alarmFlag.toString().padLeft(2, '0')}|"
      "${callFlag.toString().padLeft(2, '0')}|"
      "${notifyFlag.toString().padLeft(2, '0')}|"
      "${reminderFlag.toString().padLeft(2, '0')}";

  static Configuration? fromStorage(String storedString) {
    try {
      List<int> data =
          storedString.split("|").map((e) => int.parse(e)).toList();
      return Configuration(
          brightness: data[0],
          alarmFlag: data[1],
          callFlag: data[2],
          notifyFlag: data[3],
          reminderFlag: data[4]);
    } catch (e) {
      return null;
    }
  }

  int _getAtIndex(int j) {
    print(j);
    switch (j) {
      case 0:
        return DEV_BUZZER;
      case 1:
        return DEV_VIB;
      case 2:
        return DEV_LED;
    }
    return DEV_NONE;
  }

  void setAtIndex(int i, int j) {
    switch (i) {
      case 0:
        alarmFlag ^= _getAtIndex(j);
        break;
      case 1:
        callFlag ^= _getAtIndex(j);
        break;
      case 2:
        notifyFlag ^= _getAtIndex(j);
        break;
      case 3:
        reminderFlag ^= _getAtIndex(j);
        break;
    }
  }

  List<bool> getAlarmFlags() => [
        alarmFlag & Configuration.DEV_BUZZER > 0,
        alarmFlag & Configuration.DEV_VIB > 0,
        alarmFlag & Configuration.DEV_LED > 0
      ];

  List<bool> getCallFlags() => [
        callFlag & Configuration.DEV_BUZZER > 0,
        callFlag & Configuration.DEV_VIB > 0,
        callFlag & Configuration.DEV_LED > 0
      ];

  List<bool> getReminderFlags() => [
        reminderFlag & Configuration.DEV_BUZZER > 0,
        reminderFlag & Configuration.DEV_VIB > 0,
        reminderFlag & Configuration.DEV_LED > 0
      ];

  List<bool> getNotifyFlags() => [
        notifyFlag & Configuration.DEV_BUZZER > 0,
        notifyFlag & Configuration.DEV_VIB > 0,
        notifyFlag & Configuration.DEV_LED > 0
      ];

  @override
  String toString() {
    return 'Configuration{brightness: $brightness, alarmFlag: $alarmFlag, callFlag: $callFlag, notifyFlag: $notifyFlag, reminderFlag: $reminderFlag}';
  }
}
