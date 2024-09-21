import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

void main() {
  runApp(FedSimulatorApp());
}

class FedSimulatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '美联储模拟器',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FedSimulatorPage(),
    );
  }
}

class FedSimulatorPage extends StatefulWidget {
  @override
  _FedSimulatorPageState createState() => _FedSimulatorPageState();
}

class _FedSimulatorPageState extends State<FedSimulatorPage> {
  // 模拟的经济模型状态
  double interestRate = 2.0; // 利率
  double interestRateChange = 0;
  double gdp = 2.0; // GDP (Nominal GDP Growth Rate)
  double inflation = 2.0; // 通胀
  double unemployment = 3.5; // 失业率
  double realGDP = 10000.0; // 实际GDP，初始值10000美金

  double targetRate = 0;
  double interestRateFluctuation = 0;
  double gdpChange = 0;
  double unemploymentChange = 0;
  double inflationChange = 0;

  List<EconomicData> historyData = []; // 存储历史数据
  Timer? _timer; // 定时器，用于模拟经济变化
  bool isRunning = false; // 控制定时器的运行状态

  Random random = Random(); // 随机数生成器

  @override
  void initState() {
    super.initState();
    // 初始经济数据
    historyData.add(EconomicData(0, gdp, inflation, unemployment, interestRate, realGDP));
  }

  // 模拟经济模型，更新经济数据
  void simulateEconomy() {
    setState(() {
      double interestRateChangeEffect = interestRateChange / max(max(interestRate, -interestRate), 5);
      gdpChange = generateNormalRandom(-interestRateChangeEffect * max(unemployment, 1), 0.1);
      unemploymentChange = generateNormalRandom(
          interestRateChangeEffect,
          0.1);
      inflationChange = generateNormalRandom(
          -unemploymentChange * max(3 / unemployment, 1) + gdpChange / 2,
          0.1);

      gdp = (gdp + gdpChange).clamp(-90, 90);
      unemployment = (unemployment + unemploymentChange).clamp(0.1, 100);
      inflation = (inflation + inflationChange).clamp(-90, 90);

      // 更新实际GDP
      realGDP = realGDP * (1 + gdp / 100) / (1 + inflation / 100);
      realGDP = realGDP.clamp(1, 10000000000);

      // 添加到历史数据
      historyData.add(EconomicData(historyData.length, gdp, inflation, unemployment, interestRate, realGDP));
    });
  }

  // 开始模拟
  void startSimulation() {
    if (_timer == null || !_timer!.isActive) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        simulateEconomy();
      });
      setState(() {
        isRunning = true;
      });
    }
  }

  // 暂停模拟
  void stopSimulation() {
    if (_timer != null) {
      _timer!.cancel();
      setState(() {
        isRunning = false;
      });
    }
  }

  // 重置模拟器
  void resetSimulation() {
    stopSimulation(); // 停止模拟
    setState(() {
      // 重置状态变量
      interestRate = 2.0;
      gdp = 2.0;
      inflation = 2.0;
      unemployment = 3.5;
      realGDP = 10000.0; // 重新设定为10000美金
      interestRateChange = 0;
      historyData.clear(); // 清除历史数据
      historyData.add(EconomicData(0, gdp, inflation, unemployment, interestRate, realGDP)); // 重新添加初始数据
    });
  }

  // 判断灯的颜色
  Color determineLightColor(double value, double lower, double upper) {
    if (value >= lower + 0.5 && value <= upper - 0.5) {
      return Colors.green; // 良好
    } else if (value >= lower && value <= upper) {
      return Colors.yellow; // 一般
    } else {
      return Colors.red; // 不佳
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('美联储模拟器'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 实际GDP小面板
            Card(
              elevation: 1,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Real GDP',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '\$${realGDP.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 24, color: Colors.blueAccent),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // 显示经济数据和灯
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text('GDP: ${gdp.toStringAsFixed(2)}%'),
                    Icon(
                      Icons.circle,
                      color: determineLightColor(gdp, inflation, 100), // 设定阈值
                      size: 30,
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('通货膨胀率: ${inflation.toStringAsFixed(2)}%'),
                    Icon(
                      Icons.circle,
                      color: determineLightColor(inflation, 1.5, 3.5), // 设定阈值
                      size: 30,
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('失业率: ${unemployment.toStringAsFixed(2)}%'),
                    Icon(
                      Icons.circle,
                      color: determineLightColor(unemployment, -0.1, 5.0), // 设定阈值
                      size: 30,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(height: 20),
            // 绘制图表
            Expanded(
              child: charts.LineChart(
                _createChartData().reversed.take(50).toList(),
                animate: true,
              ),
            ),
            // 显示当前利率和调整滑块
            Text('调整利率: ${interestRate.toStringAsFixed(2)}%', style: TextStyle(fontSize: 18)),
            Slider(
              value: interestRate,
              min: -2,
              max: 10,
              divisions: 48,
              label: interestRate.toStringAsFixed(2),
              onChanged: (double value) {
                setState(() {
                  interestRateChange = value - interestRate;
                  interestRate = value;
                });
              },
            ),
            SizedBox(height: 20),
            // 控制按钮：开始、暂停和重置
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: isRunning ? null : startSimulation,
                  child: Text('开始模拟'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: isRunning ? stopSimulation : null,
                  child: Text('暂停模拟'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: resetSimulation,
                  child: Text('重置模拟'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 创建图表数据
  List<charts.Series<EconomicData, int>> _createChartData() {
    return [
      charts.Series<EconomicData, int>(
        id: 'GDP',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (EconomicData data, _) => data.time,
        measureFn: (EconomicData data, _) => data.gdp,
        data: historyData,
      ),
      charts.Series<EconomicData, int>(
        id: '通胀率',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (EconomicData data, _) => data.time,
        measureFn: (EconomicData data, _) => data.inflation,
        data: historyData,
      ),
      charts.Series<EconomicData, int>(
        id: '失业率',
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
        domainFn: (EconomicData data, _) => data.time,
        measureFn: (EconomicData data, _) => data.unemployment,
        data: historyData,
      ),
    ];
  }


}

// 用于存储经济数据的类
class EconomicData {
  final int time; // 时间步
  final double gdp; // GDP增长率
  final double inflation; // 通胀率
  final double unemployment; // 失业率
  final double interestRate; // 利率
  final double realGDP; // 实际GDP

  EconomicData(this.time, this.gdp, this.inflation, this.unemployment, this.interestRate, this.realGDP);
}
double generateNormalRandom(double mean, double stdDev) {
  final Random random = Random();
  double u1 = random.nextDouble();
  double u2 = random.nextDouble();

  // Box-Muller 变换
  double z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);

  // 转换为期望值为 mean, 标准差为 stdDev 的正态分布
  return z0 * stdDev + mean;
}