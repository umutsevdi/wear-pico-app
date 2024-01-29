import 'dart:async';

import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:nowplaying/nowplaying.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'package:smartwatch_app/model/alarm.dart';
import 'package:smartwatch_app/model/event.dart';
import 'package:smartwatch_app/model/protocol.dart';
import 'package:smartwatch_app/controller/storage_controller.dart';
import 'package:system_media_controller/system_media_controller.dart';

import '../model/steps.dart';

class BluetoothController extends GetxController {
  StorageController storage = Get.find();
  StreamSubscription<int>? listenStream;
  final bluetoothClassicPlugin = BluetoothClassic();
  final RxList<Device> _devices = <Device>[].obs;
  final RxInt _deviceStatus = Device.disconnected.obs;
  final RxString _dataToShow = "".obs;
  final _mediaController = SystemMediaController();

  Uint8List data = Uint8List(0);
  NowPlayingTrack? track;

  List<Device> get devices => _devices;

  String get dataToShow => _dataToShow.value;

  int get deviceStatus => _deviceStatus.value;

  set devices(List<Device> value) => _devices.value = value;

  set dataToShow(String value) => _dataToShow.value = value;

  @override
  void onInit() async {
    NowPlaying.instance.start();
    super.onInit();
  }

  initPermissions() async {
    await bluetoothClassicPlugin.initPermissions();
    NowPlaying.instance.requestPermissions(force: true);
    await Permission.phone.request();
  }

  Future<void> getDevices() => bluetoothClassicPlugin
      .getPairedDevices()
      .then((value) => devices = value);

  set deviceStatus(int value) => _deviceStatus.value = value;

  Future<void> connect(String address) async {
    deviceStatus = Device.connecting;
    bluetoothClassicPlugin
        .connect(address, "00001101-0000-1000-8000-00805f9b34fb")
        .then((value) {
      deviceStatus = value ? Device.connected : Device.disconnected;
      _syncData();
    }).onError((error, stackTrace) {
      deviceStatus = Device.disconnected;
    });
  }

  Future<void> disconnect() async => bluetoothClassicPlugin
      .disconnect()
      .then((value) => deviceStatus = Device.disconnected);

  void listen() {
    if (listenStream != null) {
      return;
    }
    listenStream =
        bluetoothClassicPlugin.onDeviceStatusChanged().listen((event) {
      _deviceStatus.value = event;
    });
    bluetoothClassicPlugin.onDeviceDataReceived().listen((event) {
      data = Uint8List(0);
      data = Uint8List.fromList([...event]);

      var response = ResponseType.parse(String.fromCharCodes(data));

      if (response != null) {
        switch (response.key) {
          case ResponseType.STEP:
            if (response.value != null) {
              DateTime now = DateTime.now();
              int index = storage.steps.indexWhere((element) =>
                  element.date == DateTime(now.year, now.month, now.day));
              Steps step = Steps(
                  date: DateTime(now.year, now.month, now.day),
                  steps: response.value ?? 0);
              if (index == -1) {
                storage.stepOperator.add(step);
              } else {
                storage.stepOperator.update(index, step);
              }
            }
            break;
          case ResponseType.OSC_PREV:
            _mediaController.skipPrevious();
            break;
          case ResponseType.OSC_PLAY_PAUSE:
            if (track != null) {
              if (track!.isPlaying) {
                _mediaController.pause();
              } else if (track!.isPaused) {
                _mediaController.play();
              }
              write(requestType: RequestType.OSC, data: [
                track!.isPlaying ? 't' : 'f',
                track!.title ?? " ",
                track!.artist ?? " "
              ]);
            }
            break;
          case ResponseType.OSC_NEXT:
            _mediaController.skipNext();
            break;
          default:
        }
        _dataToShow.value = response.key.toString();
      } else {
        _dataToShow.value = "No Data";
      }
    });
    PhoneState.stream.listen((event) {
      if (event.status == PhoneStateStatus.CALL_INCOMING &&
          event.number != null) {
        write(requestType: RequestType.CALL_BEGIN, data: [event.number!]);
      } else if (event.status == PhoneStateStatus.CALL_ENDED ||
          event.status == PhoneStateStatus.CALL_STARTED) {
        write(requestType: RequestType.CALL_END);
      }
    });
    NowPlaying.instance.stream.listen((event) {
      if (event.title != null) {
        track = event;
        write(requestType: RequestType.OSC, data: [
          event.isPlaying ? "t" : "f",
          event.title ?? " ",
          event.artist ?? " "
        ]);
      }
    });
  }

  Future<void> write(
      {required RequestType requestType, List<String>? data}) async {
    if (deviceStatus == Device.connected) {
      String message = requestType.prepareMessage(data);
      bluetoothClassicPlugin.write(message).onError((error, stackTrace) {
        deviceStatus = Device.disconnected;
        return true;
      });
    }
  }

  sendAlarms(List<Alarm> alarms) async => write(
      requestType: RequestType.FETCH_ALARM,
      data: List.of([
        alarms.length.toString(),
        ...(alarms.map((element) => element.serialize()))
      ]));

  sendEvents(List<ReminderEvent> events) async {
    List<String> serializedEvents = events
        .where((element) => element.date.isAfter(DateTime.now()))
        .indexed
        .where((entry) => entry.$1 < 4)
        .toList()
        .reversed
        .map((e) => e.$2.serialize())
        .toList();
    write(
        requestType: RequestType.REMINDER,
        data:
            List.of([serializedEvents.length.toString(), ...serializedEvents]));
  }

  Future<void> _syncData() async => write(
          requestType: RequestType.FETCH_DATE,
          data: [DateFormat('yyyyMMddHHmmss').format(DateTime.now())])
      .then((value) => write(
          requestType: RequestType.CONFIG,
          data: [storage.steps.first.serialize()]))
      .then((value) => sendAlarms(storage.alarms))
      .then((value) => sendEvents(storage.events));
}
