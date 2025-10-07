import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class Currency {
  static String fcfa(num value, {int decimals = 0}) {
    final format = NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: decimals);
    final text = format.format(value);
    return decimals > 0 ? '$text FCFA' : '${text.replaceAll(',', ' ')} FCFA';
  }
}

/// Formatter para campos de texto monetários (FCFA)
class FcfaTextInputFormatter extends TextInputFormatter {
  final int decimalDigits;

  FcfaTextInputFormatter({this.decimalDigits = 0});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final clean = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      return const TextEditingValue(text: '');
    }

    if (decimalDigits == 0) {
      final formatted = NumberFormat.decimalPattern().format(int.parse(clean));
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else {
      // Inserir ponto decimal de acordo com decimalDigits
      final value = int.parse(clean);
      final divisor = pow10(decimalDigits);
      final num number = value / divisor;
      final formatted = NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: decimalDigits).format(number).trim();
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  int pow10(int n) {
    var r = 1;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }
}
