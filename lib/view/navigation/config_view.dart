import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartwatch_app/controller/bluetooth_controller.dart';
import 'package:smartwatch_app/controller/storage_controller.dart';

import '../../model/configuration.dart';
import '../../model/protocol.dart';

class ConfigView extends StatefulWidget {
  const ConfigView({super.key});

  @override
  State<ConfigView> createState() => _ConfigViewState();
}

class _ConfigViewState extends State<ConfigView> {
  BluetoothController btController = Get.find<BluetoothController>();
  StorageController storage = Get.find<StorageController>();
  late RxList<List<bool>> flags = RxList(<List<bool>>[
    storage.config.first.getAlarmFlags(),
    storage.config.first.getCallFlags(),
    storage.config.first.getNotifyFlags(),
    storage.config.first.getReminderFlags()
  ]);
  late Rx<Configuration> config = storage.config.first.obs;
  late RxDouble sliderValue = RxDouble(config.value.brightness.toDouble());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Obx(() => Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width <
                    MediaQuery.of(context).size.height
                ? MediaQuery.of(context).size.width
                : MediaQuery.of(context).size.width / 2,
            child: btController.deviceStatus == Device.connected
                ? Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const SizedBox(width: 10),
                      Icon(config.value.brightness > 80
                          ? Icons.brightness_high
                          : config.value.brightness > 50
                              ? Icons.brightness_medium
                              : Icons.brightness_low),
                      const SizedBox(width: 10),
                      Slider(
                          min: 0,
                          max: 100,
                          divisions: 10,
                          onChanged: (value) {
                            if (value != config.value.brightness.toDouble()) {
                              config.value.brightness = (value).toInt();
                              sliderValue.value = value;
                              storage.configOperator
                                  .update(0, config.value)
                                  .then((value) => btController.write(
                                      requestType: RequestType.CONFIG,
                                      data: [value.first.serialize()]));
                            }
                          },
                          value: sliderValue.value),
                    ]),
                    _toggleCard(0, (values) {}),
                    _toggleCard(1, (values) {}),
                    _toggleCard(2, (values) {}),
                    _toggleCard(3, (values) {}),
                  ])
                : const Text("Device is not connected"))));
  }

  onUpdate(List<bool> values) {
    storage.configOperator.update(0, config.value).then((value) => btController
        .write(
            requestType: RequestType.CONFIG, data: [value.first.serialize()]));
  }

  _toggleCard(int index, Function(List<bool>) onSelected) => Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const SizedBox(width: 10),
        Icon(index == 0
            ? Icons.alarm
            : index == 1
                ? Icons.call
                : index == 2
                    ? Icons.notifications_on_outlined
                    : Icons.calendar_month),
        Text(
            index == 0
                ? "Alarms".padRight(7)
                : index == 1
                    ? "Calls".padRight(8)
                    : index == 2
                        ? "Notifications"
                        : "Reminders".padRight(4),
            textAlign: TextAlign.justify),
        const SizedBox(width: 25),
        ToggleButtons(
            borderRadius: BorderRadius.circular(10),
            onPressed: (i) {
              flags[index][i] = !flags[index][i];
              config.value.setAtIndex(index, i);
              storage.configOperator.update(0, config.value).then((value) =>
                  btController.write(
                      requestType: RequestType.CONFIG,
                      data: [value.first.serialize()]));
            },
            isSelected: flags[index],
            children: const [
              Icon(Icons.volume_down_rounded),
              Icon(Icons.vibration),
              Icon(Icons.flash_on),
            ]),
        const SizedBox(width: 10),
      ]));
}
