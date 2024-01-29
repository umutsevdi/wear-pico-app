import 'dart:async';

import 'package:get/get.dart';
import 'package:reflex/reflex.dart';
import 'package:smartwatch_app/controller/bluetooth_controller.dart';
import 'package:smartwatch_app/model/protocol.dart';

class NotificationController extends GetxController {
  BluetoothController bluetoothController = Get.find();
  StreamSubscription<ReflexEvent>? _subscription;

  Reflex reflex = Reflex(
    debug: false,
//    packageNameList: ["com.whatsapp", "com.tyup"],
    packageNameExceptionList: ["com.android.systemui"],
/*    autoReply: AutoReply(
      packageNameList: ["com.whatsapp"],
      message: "[Reflex] This is an automated reply.",
    ),*/
  );

  Future<void> initPlatformState() async {
    await Reflex.requestPermission();
    Reflex.isPermissionGranted.then((value) => startListening());
  }

  void startListening() {
    ReflexEvent? previousEvent;
    _subscription = reflex.notificationStream!.listen((ReflexEvent event) {
      if (event.type == ReflexEventType.notification) {
        if (event.title == previousEvent?.title &&
            event.message == previousEvent?.message &&
            event.packageName == previousEvent?.packageName) {
          return;
        }
        if (event.packageName!.contains("music")) {
          bluetoothController.write(
              data: ["t", event.title ?? " ", event.message ?? " "],
              requestType: RequestType.OSC);
        } else if (event.packageName!.contains("android") ==
                false /* probably unnecessary notification */
            ||
            event.packageName!.contains("messag") /* message notification) */) {
          bluetoothController.write(
              data: [event.title ?? "Notification", event.message ?? " "],
              requestType: RequestType.NOTIFY);
        }
        previousEvent = event;
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
  }
}
