import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_charts/flutter_charts.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smartwatch_app/controller/storage_controller.dart';
import 'package:smartwatch_app/model/protocol.dart';

import '../../controller/bluetooth_controller.dart';
import '../../model/steps.dart';

class StepsView extends StatefulWidget {
  const StepsView({super.key});

  @override
  State<StepsView> createState() => _StepsViewState();
}

class _StepsViewState extends State<StepsView> {
  BluetoothController btController = Get.find<BluetoothController>();
  StorageController storage = Get.find<StorageController>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    btController.write(requestType: RequestType.STEP);
    return Scaffold(
        body: Center(
            child: ListView(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
      children: [
        Card(
          child: SizedBox(
              height: MediaQuery.of(context).size.height / 5,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Today", style: TextStyle(fontSize: 25)),
                    Center(
                        child: Obx(() => Text(
                            style: const TextStyle(
                                color: Colors.cyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 45),
                            storage.steps.isNotEmpty
                                ? storage.steps[storage.steps.length - 1].steps
                                    .toString()
                                : "")))
                  ])),
        ),
        Obx(() => storage.steps.isNotEmpty
            ? Card(
                child: Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 15),
                    height: (MediaQuery.of(context).size.width +
                            MediaQuery.of(context).size.height) /
                        5,
                    child: Obx(
                      () {
                        Set<Steps> data = storage.steps
                            .where((element) => DateTime.now()
                                .add(const Duration(days: -7))
                                .isBefore(element.date))
                            .toSet();
                        return data.isNotEmpty
                            ? LineChart(painter: _lineChartPainter(data))
                            : Container();
                      },
                    )))
            : Container()),
        Obx(() => Card(
            child: storage.steps.length > 1
                ? SizedBox(
                    height: MediaQuery.of(context).size.height / 3,
                    child: _stepListViewBuilder())
                : Container())),
      ],
    )));
  }

  _lineChartPainter(Set<Steps> data) => LineChartPainter(
      lineChartContainer: LineChartTopContainer(
          chartData: ChartData(
              dataRowsColors: [Theme.of(context).focusColor],
              dataRows: [data.map((e) => e.steps.toDouble()).toList()],
              xUserLabels:
                  data.map((e) => DateFormat("dd/MM").format(e.date)).toList(),
              dataRowsLegends: const ["Steps"],
              chartOptions: ChartOptions(
                  legendOptions:
                      const LegendOptions(isLegendContainerShown: false),
                  lineChartOptions: LineChartOptions(
                    hotspotOuterPaintColor: Colors.primaries.last,
                    hotspotInnerPaintColor: Colors.cyan,
                    lineStrokeWidth: 3,
                  ),
                  dataContainerOptions: DataContainerOptions(
                      yTransform: (num y) => log(y + 1) / ln10,
                      yInverseTransform: inverseLog10)))));

  _stepListViewBuilder() => ListView.builder(
      itemCount: storage.steps.length - 1,
      itemBuilder: ((context, index) {
        DateTime key = storage.steps[storage.steps.length - index - 2].date;
        int value = storage.steps[storage.steps.length - index - 2].steps;
        int dif = DateTime.now().difference(key).inHours.abs();
        String date = dif < 24
            ? "Today"
            : dif < 48
                ? "Yesterday"
                : DateFormat("dd/MM/yyyy").format(key);
        return ListTile(
          leading: Text(date, style: const TextStyle(fontSize: 16)),
          trailing: Text(value.toString(),
              style: const TextStyle(fontSize: 20, color: Colors.cyan)),
        );
      }));
}
