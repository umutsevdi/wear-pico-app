import 'dart:async';

import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartwatch_app/view/navigation/alarm_view.dart';
import 'package:smartwatch_app/view/navigation/config_view.dart';
import 'package:smartwatch_app/view/navigation/reminder_view.dart';
import 'package:smartwatch_app/view/navigation/steps_view.dart';

import '../controller/bluetooth_controller.dart';
import '../controller/notification_controller.dart';
import '../model/protocol.dart';

enum Page {
  alarm(idx: 0, text: "Alarm", icon: Icon(Icons.alarm)),
  reminder(idx: 1, text: "Reminder", icon: Icon(Icons.task_alt)),
  steps(idx: 2, text: "Steps", icon: Icon(Icons.directions_walk)),
  config(idx: 3, text: "Settings", icon: Icon(Icons.settings));

  final int idx;
  final String text;
  final Icon icon;

  const Page({required this.idx, required this.text, required this.icon});

  getNavigationItem() => BottomNavigationBarItem(
      icon: icon, label: text, backgroundColor: Colors.primaries.last);

  static Page? of(int id) => Page.values.firstWhere((page) => page.idx == id);
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int currentIndex = 1;
  bool isInitialized = false;
  BluetoothController controller = Get.find<BluetoothController>();
  NotificationController notificationController =
      Get.find<NotificationController>();

  @override
  void initState() {
    super.initState();
    if (!isInitialized) {
      controller.initPermissions();
      controller.listen();
      notificationController.initPlatformState();
      notificationController.startListening();
      Timer.periodic(const Duration(seconds: 20),
          (timer) => controller.write(requestType: RequestType.HB));
    }
    isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leadingWidth: double.infinity,
          leading: Row(children: [
            const SizedBox(width: 20),
            Page.of(currentIndex)!.icon,
            const SizedBox(width: 15),
            Text(Page.of(currentIndex)!.text,
                style: const TextStyle(fontSize: 30)),
          ]),
          actions: [
            Obx(() => ElevatedButton(
                  onPressed: () => controller.deviceStatus == Device.connected
                      ? _showDisconnectPopup(context)
                      : controller
                          .getDevices()
                          .then((value) => _showSelectionPopup(context)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(controller.deviceStatus == Device.connected
                        ? "Connected"
                        : "Disconnected"),
                    const SizedBox(width: 15),
                    Icon(controller.deviceStatus == Device.connected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled),
                  ]),
                )),
            const SizedBox(width: 35),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          unselectedItemColor: Colors.white54,
          selectedItemColor: Colors.white,
          onTap: (value) {
            setState(() => currentIndex = value);
          },
          items: [
            Page.alarm.getNavigationItem(),
            Page.reminder.getNavigationItem(),
            Page.steps.getNavigationItem(),
            Page.config.getNavigationItem()
          ],
          currentIndex: currentIndex,
        ),
        body: Container(
            margin: const EdgeInsets.symmetric(vertical: 30, horizontal: 5),
            child: <Widget>[
              const AlarmView(),
              const ReminderView(),
              const StepsView(),
              const ConfigView()
            ][currentIndex]));
  }

  void _showSelectionPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: controller.devices.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              leading: const Icon(Icons.devices),
              title: Text(controller.devices[index].name ?? ""),
              onTap: () {
                controller.connect(controller.devices[index].address);
                Navigator.pop(context, controller.devices[index]);
                _showConnectionStatus(context);
              },
            );
          },
        );
      },
    );
  }

  void _showDisconnectPopup(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) => SizedBox(
            height: MediaQuery.of(context).size.height / 3 * 2,
            width: double.infinity,
            child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                        "Are you sure you want to disconnect from the smartwatch?"),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                              onPressed: () => controller
                                  .disconnect()
                                  .then((value) => Navigator.pop(context)),
                              child: const Text("Confirm")),
                          ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel")),
                        ])
                  ],
                ))));
  }

  void _showConnectionStatus(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() {
                    switch (controller.deviceStatus) {
                      case Device.connecting:
                        return const CircularProgressIndicator();
                      case Device.connected:
                        return const Icon(Icons.bluetooth_connected);
                      case Device.disconnected:
                        return const Icon(Icons.bluetooth_disabled);
                      default:
                        return const SizedBox(height: 16);
                    }
                  }),
                  const SizedBox(height: 16.0),
                  Obx(() => Text(controller.deviceStatus == Device.connected
                      ? 'Connected.'
                      : controller.deviceStatus == Device.connecting
                          ? "Connecting"
                          : "Could not connect")),
                  const SizedBox(height: 16.0),
                  Obx(() => controller.deviceStatus != Device.connecting
                      ? ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Continue'))
                      : const SizedBox(height: 16))
                ],
              ),
            ),
          );
        });
  }
}
