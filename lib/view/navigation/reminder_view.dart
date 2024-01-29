import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smartwatch_app/controller/storage_controller.dart';
import 'package:smartwatch_app/model/event.dart';

import '../../controller/bluetooth_controller.dart';
import '../../controller/notification_controller.dart';

class ReminderView extends StatefulWidget {
  const ReminderView({super.key});

  @override
  State<ReminderView> createState() => _ReminderViewState();
}

class _ReminderViewState extends State<ReminderView> {
  BluetoothController btController = Get.find<BluetoothController>();
  StorageController storage = Get.find<StorageController>();
  NotificationController notificationController =
      Get.find<NotificationController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addReminderPicker((e) => storage.eventOperator
              .add(e)
              .then((value) => btController.sendEvents(value))),
          tooltip: "Add a new reminder",
          child: const Icon(Icons.add),
        ),
        body: Center(
            child: Obx(() => storage.events.isNotEmpty
                ? SizedBox(
                    child: ListView.builder(
                      itemCount: storage.events.length,
                      itemBuilder: ((context, index) => ListTile(
                          onTap: () => _addReminderPicker(
                              (e) => storage.eventOperator
                                  .update(index, e)
                                  .then((value) =>
                                      btController.sendEvents(value)),
                              event: storage.events[index]),
                          title: _cardBuilder(index))),
                    ))
                : const Text("No reminder found"))));
  }

  _addReminderPicker(Function(ReminderEvent) onConfirm,
      {ReminderEvent? event}) {
    RxString title = (event?.title ?? "").obs;
    RxString text = (event?.description ?? "").obs;
    TextEditingController titleController =
        TextEditingController(text: title.value);
    TextEditingController textEditingController =
        TextEditingController(text: text.value);

    Rx<DateTime>? date = (event?.date ?? DateTime.now()).obs;

    return showModalBottomSheet(
        context: context,
        builder: (BuildContext context) => SizedBox(
            height: MediaQuery.of(context).size.height / 3 * 2,
            width: MediaQuery.of(context).size.width,
            child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
                child: ListView(children: [
                  const Text("Create a new reminder",
                      style: TextStyle(fontSize: 30)),
                  TextField(
                    controller: titleController,
                    onChanged: (data) => title.value = titleController.text,
                    decoration: const InputDecoration(labelText: 'Event'),
                    maxLines: 1,
                    maxLength: 30,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textEditingController,
                    onChanged: (data) =>
                        text.value = textEditingController.text,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                    maxLength: 120,
                  ),
                  SizedBox(
                      height: 300,
                      child: CupertinoDatePicker(
                        initialDateTime: (event?.date ?? DateTime.now())
                                .isAfter(DateTime.now())
                            ? event?.date
                            : DateTime.now().add(const Duration(minutes: 1)),
                        minimumDate: DateTime.now(),
                        onDateTimeChanged: (newDate) => date.value = newDate,
                      )),
                  Obx(() => title.value.isNotEmpty && text.value.isNotEmpty
                      ? ElevatedButton(
                          onPressed: () {
                            onConfirm(ReminderEvent(
                                title: title.value,
                                description: text.value,
                                date: date.value));
                            Navigator.pop(context);
                          },
                          child: const Text("Confirm"))
                      : Text(
                          "Please fill the missing fields: ${title.value.isEmpty ? "Title" : ""} ${text.value.isEmpty ? "Description" : ""}",
                          style: const TextStyle(color: Colors.red)))
                ]))));
  }

  _cardBuilder(int index) => Card(
      child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(storage.events[index].title,
                    style: const TextStyle(fontSize: 24)),
                Text(storage.events[index].description),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        const Icon(Icons.calendar_month),
                        Text(DateFormat("hh:mm dd/MM/yyyy")
                            .format(storage.events[index].date))
                      ]),
                      IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => storage.eventOperator
                              .delete(index)
                              .then((value) => btController.sendEvents(value)))
                    ])
              ])));
}
