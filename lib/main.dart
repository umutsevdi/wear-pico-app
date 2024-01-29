import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartwatch_app/controller/bluetooth_controller.dart';
import 'package:smartwatch_app/controller/storage_controller.dart';
import 'package:smartwatch_app/view/main_view.dart';

import 'controller/notification_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(StorageController());
  Get.put(BluetoothController());
  Get.put(NotificationController());
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Smartwatch App",
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home: const MainView());
  }
}
