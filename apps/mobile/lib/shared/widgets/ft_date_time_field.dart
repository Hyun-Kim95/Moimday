import 'package:flutter/material.dart';

import '../../core/datetime/date_time_utils.dart';

class FtDateTimeField extends StatelessWidget {
  const FtDateTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isAllDay = false,
    this.onAllDayChanged,
    this.showAllDayToggle = false,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool isAllDay;
  final ValueChanged<bool>? onAllDayChanged;
  final bool showAllDayToggle;

  Future<void> _pick(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('ko'),
    );
    if (date == null || !context.mounted) return;

    var time = TimeOfDay.fromDateTime(value);
    if (!isAllDay) {
      final picked = await showTimePicker(context: context, initialTime: time);
      if (picked == null) return;
      time = picked;
    }

    onChanged(
      DateTime(
        date.year,
        date.month,
        date.day,
        isAllDay ? 0 : time.hour,
        isAllDay ? 0 : time.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _pick(context),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            child: Text(
              DateTimeUtils.formatDisplay(value, isAllDay: isAllDay),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        if (showAllDayToggle && onAllDayChanged != null)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('종일'),
            value: isAllDay,
            onChanged: onAllDayChanged,
          ),
      ],
    );
  }
}
