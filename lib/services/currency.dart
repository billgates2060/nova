import 'package:intl/intl.dart';

class Currency {
  static String fcfa(num value) {
    final f = NumberFormat.decimalPattern();
    return '${f.format(value)} FCFA';
  }
}
