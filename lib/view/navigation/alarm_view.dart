import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartwatch_app/controller/bluetooth_controller.dart';
import 'package:smartwatch_app/controller/storage_controller.dart';

import '../../model/alarm.dart';

class AlarmView extends StatefulWidget {
  const AlarmView({super.key});

  @override
  State<AlarmView> createState() => _AlarmViewState();
}

class _AlarmViewState extends State<AlarmView> {
  BluetoothController btController = Get.find<BluetoothController>();
  StorageController storage = Get.find<StorageController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: Obx(() => storage.alarms.length < 4
            ? FloatingActionButton(
                onPressed: () => _addAlarmPicker((alarm) => storage
                    .alarmOperator
                    .add(alarm)
                    .then((value) => btController.sendAlarms(value))),
                tooltip: "Add a new alarm",
                child: const Icon(Icons.add),
              )
            : const SizedBox(height: 10)),
        body: Center(
            child: Obx(() => storage.alarms.isNotEmpty
                ? _alarmListViewBuilder()
                : const Text("No alarms found"))));
  }

  Future _addAlarmPicker(Function(Alarm) onPressed, {Alarm? alarm}) {
    RxInt hours = (alarm?.hour ?? DateTime.now().hour).obs;
    RxInt minutes = (alarm?.minute ?? DateTime.now().minute).obs;

    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => SizedBox(
        height: 300,
        width: MediaQuery.of(context).size.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoTimerPicker(
                initialTimerDuration:
                    Duration(hours: hours.value, minutes: minutes.value),
                mode: CupertinoTimerPickerMode.hm,
                onTimerDurationChanged: (Duration duration) {
                  hours.value = duration.inHours;
                  minutes.value = duration.inMinutes - hours.value * 60;
                }),
            IconButton(
                iconSize: 40,
                onPressed: () {
                  onPressed(Alarm(hour: hours.value, minute: minutes.value));
                  Navigator.pop(context);
                },
                icon: Icon(alarm == null ? Icons.add : Icons.edit)),
          ],
        ),
      ),
    );
  }

  _alarmListViewBuilder() => ListView.builder(
        itemCount: storage.alarms.length,
        itemBuilder: ((context, index) => ListTile(
            onTap: () => _addAlarmPicker(
                (alarm) => storage.alarmOperator
                    .update(index, alarm)
                    .then((value) => btController.sendAlarms(value)),
                alarm: storage.alarms[index]),
            title: Card(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                  Text(
                      "${storage.alarms[index].hour.toString().padLeft(2, '0')}:${storage.alarms[index].minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(fontSize: 30, color: Colors.cyan)),
                  const SizedBox(width: 40),
                  IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => storage.alarmOperator
                          .delete(index)
                          .then((value) => btController.sendAlarms(value)))
                ])))),
      );
}
