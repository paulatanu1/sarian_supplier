import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../theme/app_colors.dart';

class OrderTimeline extends StatelessWidget {
  final List<StatusEvent> events;
  const OrderTimeline({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final sorted = [...events]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Column(
      children: List.generate(sorted.length, (i) {
        final e       = sorted[i];
        final isLast  = i == sorted.length - 1;
        final isCancelled = e.status == 'cancelled';
        final color   = isCancelled ? AppColors.cancelled : AppColors.statusColor(e.status);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: dot + line
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: AppColors.divider,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right: status text + timestamp
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.status.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: color,
                        ),
                      ),
                      if (e.note != null && e.note!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(e.note!, style: Theme.of(context).textTheme.bodySmall),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        _formatTime(e.timestamp),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final a = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}, $h:$m $a';
  }

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];
}
