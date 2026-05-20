import 'package:flutter/material.dart';

import '../../core/models/event_status.dart';
import 'ft_action_chip.dart';

class FtStatusChip extends StatelessWidget {
  const FtStatusChip({super.key, required this.status});

  final EventStatus status;

  @override
  Widget build(BuildContext context) {
    final kind = switch (status) {
      EventStatus.pollOpen => FtActionChipKind.poll,
      EventStatus.attendanceOpen => FtActionChipKind.attend,
      EventStatus.cancelled => FtActionChipKind.cancelled,
      EventStatus.finalized => FtActionChipKind.neutral,
    };
    return FtActionChip(label: status.label, kind: kind);
  }
}
