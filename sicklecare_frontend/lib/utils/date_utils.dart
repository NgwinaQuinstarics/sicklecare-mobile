import 'package:intl/intl.dart';

String fmtDate(DateTime d) => DateFormat('EEE, MMM d').format(d);
String fmtTime(DateTime d) => DateFormat('h:mm a').format(d);
String fmtDateTime(DateTime d) => DateFormat('MMM d • h:mm a').format(d);
