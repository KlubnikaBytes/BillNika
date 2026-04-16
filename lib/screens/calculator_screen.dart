import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String input = "";
  String result = "0";
  List<String> history = [];

  // ✅ STORE ALL RESULTS FOR GT
  List<double> gtValues = [];

  // ================= EVALUATION =================
  double eval(String exp) {
    try {
      exp = exp.replaceAll('x', '*').replaceAll('÷', '/');

      Parser p = Parser();
      Expression expression = p.parse(exp);
      ContextModel cm = ContextModel();

      return expression.evaluate(EvaluationType.REAL, cm);
    } catch (e) {
      return 0;
    }
  }

  // ================= INPUT =================
  void add(String val) {
    setState(() => input += val);
  }

  void clear() {
    setState(() {
      input = "";
      result = "0";
      history.clear();
      gtValues.clear(); // ✅ RESET GT ALSO
    });
  }

  // ================= EQUAL =================
  void calculate() {
    double res = eval(input);

    setState(() {
      history.insert(0, "$input = ${res.toStringAsFixed(0)}"); // ✅ latest top
      result = res.toStringAsFixed(2);
      gtValues.add(res); // ✅ store for GT
      input = "";
    });
  }

  // ================= GT =================
  void calculateGT() {
    double total = 0;
    for (var v in gtValues) {
      total += v;
    }

    setState(() {
      history.insert(0, "GT = ${total.toStringAsFixed(0)}");
      result = total.toStringAsFixed(2);
    });
  }

  // ================= GST ADD =================
  void applyGST(double percent) {
    double val = eval(input);
    double gst = val * percent / 100;
    double total = val + gst;

    double cgst = gst / 2;
    double sgst = gst / 2;

    setState(() {
      history.insert(0,
          "${val.toStringAsFixed(0)} + GST ${percent.toStringAsFixed(0)}% = ${total.toStringAsFixed(2)}");
      history.insert(0,
          "GST: ${gst.toStringAsFixed(2)}  SGST: ${cgst.toStringAsFixed(2)}  CGST: ${sgst.toStringAsFixed(2)}");

      result = total.toStringAsFixed(2);
      gtValues.add(total); // ✅ store
      input = "";
    });
  }

  // ================= GST REMOVE =================
  void removeGST(double percent) {
    double val = eval(input);

    double base = val / (1 + percent / 100);
    double gst = val - base;

    double cgst = gst / 2;
    double sgst = gst / 2;

    setState(() {
      history.insert(0,
          "${val.toStringAsFixed(0)} - GST ${percent.toStringAsFixed(0)}% = ${base.toStringAsFixed(2)}");
      history.insert(0,
          "GST: ${gst.toStringAsFixed(2)}  SGST: ${cgst.toStringAsFixed(2)}  CGST: ${sgst.toStringAsFixed(2)}");

      result = base.toStringAsFixed(2);
      gtValues.add(base); // ✅ store
      input = "";
    });
  }

  // ================= PERCENT =================
  void applyPercent(double percent) {
    double val = eval(input);
    double res = val + (val * percent / 100);

    setState(() {
      history.insert(0,
          "${val.toStringAsFixed(0)} + $percent% = ${res.toStringAsFixed(2)}");
      result = res.toStringAsFixed(2);
      gtValues.add(res); // ✅ store
      input = "";
    });
  }

  void minusPercent(double percent) {
    double val = eval(input);
    double res = val - (val * percent / 100);

    setState(() {
      history.insert(0,
          "${val.toStringAsFixed(0)} - $percent% = ${res.toStringAsFixed(2)}");
      result = res.toStringAsFixed(2);
      gtValues.add(res); // ✅ store
      input = "";
    });
  }

  // ================= CASH =================
  void cashIn() {
    double val = eval(input);
    double res = double.parse(result) + val;

    setState(() {
      history.insert(0, "Cash IN: $val");
      result = res.toStringAsFixed(2);
      gtValues.add(res); // ✅ store
      input = "";
    });
  }

  void cashOut() {
    double val = eval(input);
    double res = double.parse(result) - val;

    setState(() {
      history.insert(0, "Cash OUT: $val");
      result = res.toStringAsFixed(2);
      gtValues.add(res); // ✅ store
      input = "";
    });
  }

  // ================= BUTTON =================
  Widget btn(String text,
      {Color color = const Color(0xFF3A3A5A), Function()? onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.all(18),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onTap ?? () => add(text),
          child: Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Calculator")),

      body: Column(
        children: [
          // DISPLAY
          Container(
            height: 150,
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // INPUT (LIVE)
                Text(
                  input,
                  style: const TextStyle(
                      fontSize: 20, color: Colors.black54),
                ),

                const SizedBox(height: 5),

                // HISTORY (LATEST TOP)
                Expanded(
                  child: ListView(
                    reverse: false,
                    children: history
                        .map((e) => Text(
                      e,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.grey),
                    ))
                        .toList(),
                  ),
                ),

                // RESULT
                Text(
                  "= $result",
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const Divider(),

          // TOP ROW
          Row(
            children: [
              btn("GT", color: Colors.grey, onTap: calculateGT),
              btn("MU", color: Colors.grey),
              btn("Cash IN", color: Colors.green, onTap: cashIn),
              btn("Cash OUT", color: Colors.red, onTap: cashOut),
            ],
          ),

          // GST +
          Row(
            children: [
              btn("+3%", color: Colors.grey, onTap: () => applyGST(3)),
              btn("+5%", color: Colors.grey, onTap: () => applyGST(5)),
              btn("+18%", color: Colors.grey, onTap: () => applyGST(18)),
              btn("+40%", color: Colors.grey, onTap: () => applyGST(40)),
              btn("+GST", color: Colors.grey),
            ],
          ),

          // GST -
          Row(
            children: [
              btn("-3%", color: Colors.grey, onTap: () => removeGST(3)),
              btn("-5%", color: Colors.grey, onTap: () => removeGST(5)),
              btn("-18%", color: Colors.grey, onTap: () => removeGST(18)),
              btn("-40%", color: Colors.grey, onTap: () => removeGST(40)),
              btn("-GST", color: Colors.grey),
            ],
          ),

          // NUM PAD
          Expanded(
            child: Column(
              children: [
                Row(children: [
                  btn("7"),
                  btn("8"),
                  btn("9"),
                  btn("%", color: Colors.grey),
                  btn("AC", color: Colors.orange, onTap: clear),
                ]),
                Row(children: [
                  btn("4"),
                  btn("5"),
                  btn("6"),
                  btn("-", color: Colors.grey),
                  btn("÷", color: Colors.grey),
                ]),
                Row(children: [
                  btn("1"),
                  btn("2"),
                  btn("3"),
                  btn("+", color: Colors.grey),
                  btn("x", color: Colors.grey),
                ]),
                Row(children: [
                  btn("0"),
                  btn("00"),
                  btn("."),
                  btn("=", color: Colors.green, onTap: calculate),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}