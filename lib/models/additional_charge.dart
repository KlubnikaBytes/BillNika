import 'package:flutter/material.dart';

class AdditionalCharge {
  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;

  AdditionalCharge({
    String name = '',
    double amount = 0,
  })  : nameCtrl = TextEditingController(text: name),
        amountCtrl = TextEditingController(
          text: amount == 0 ? '' : amount.toString(),
        );

  double get amount => double.tryParse(amountCtrl.text) ?? 0;

  Map<String, dynamic> toApiJson() {
    return {
      "name": nameCtrl.text,
      "amount": amount,
    };
  }
}