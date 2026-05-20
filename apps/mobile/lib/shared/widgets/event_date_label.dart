import 'package:flutter/material.dart';

import '../../core/datetime/date_time_utils.dart';

class EventDateLabel extends StatelessWidget {
  const EventDateLabel({super.key, required this.iso, this.isAllDay = false, this.style});

  final String? iso;
  final bool isAllDay;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      DateTimeUtils.formatDisplayFromIso(iso, isAllDay: isAllDay),
      style: style ?? Theme.of(context).textTheme.bodyMedium,
    );
  }
}
