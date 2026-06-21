import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../models/order_model.dart';
import '../../../providers/orders_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _filterIdx = 0; // 0=Today 1=Week 2=Month 3=Custom
  DateTimeRange? _custom;

  DateRange get _range {
    final now  = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_filterIdx) {
      0 => DateRange(today, now),
      1 => DateRange(today.subtract(const Duration(days: 6)), now),
      2 => DateRange(DateTime(now.year, now.month, 1), now),
      _ => _custom != null
          ? DateRange(_custom!.start, _custom!.end)
          : DateRange(today, now),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(userOrdersProvider);
    final orders = ordersAsync.asData?.value ?? [];

    final r     = _range;
    final filtered = orders.where((o) =>
        o.createdAt.isAfter(r.from.subtract(const Duration(seconds: 1))) &&
        o.createdAt.isBefore(r.to.add(const Duration(seconds: 1)))).toList();

    final total    = filtered.length;
    final delivered = filtered.where((o) => o.status == 'delivered').length;
    final pending   = filtered.where((o) => o.status == 'pending').length;
    final revenue  = filtered.where((o) => o.status == 'delivered')
        .fold<double>(0, (s, o) => s + o.totalAmount);

    // Category breakdown
    final catMap = <String, int>{};
    for (final o in filtered) {
      for (final item in o.items) {
        catMap[item.company] = (catMap[item.company] ?? 0) + item.quantity;
      }
    }
    final topCats = (catMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              ..._buildChips(),
              if (_filterIdx == 3)
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(_custom != null
                      ? '${_custom!.start.display} – ${_custom!.end.display}'
                      : 'Pick Range'),
                  onPressed: _pickRange,
                ),
            ]),
          ),
          const SizedBox(height: 16),

          // Summary cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _SummaryCard('Total Orders',  '$total',      AppColors.info),
              _SummaryCard('Delivered',     '$delivered',  AppColors.success),
              _SummaryCard('Pending',       '$pending',    AppColors.warning),
              _SummaryCard('Revenue',       revenue.inr,   AppColors.primary),
            ],
          ),
          const SizedBox(height: 24),

          // Bar chart — orders by status
          if (total > 0) ...[
            Text('Order Summary', style: context.textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (total * 1.3).toDouble(),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Text(
                          ['Pending','Accepted','Dispatch','Delivered','Cancelled'][v.toInt()],
                          style: const TextStyle(fontSize: 8),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: _barGroups(filtered),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Top companies pie
          if (topCats.isNotEmpty) ...[
            Text('Top Companies by Qty', style: context.textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PieChart(PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(topCats.length, (i) {
                  final colors = [AppColors.primary, AppColors.accent,
                      AppColors.info, AppColors.warning, AppColors.success];
                  return PieChartSectionData(
                    value: topCats[i].value.toDouble(),
                    title: topCats[i].key.length > 10
                        ? '${topCats[i].key.substring(0, 10)}…'
                        : topCats[i].key,
                    color: colors[i % colors.length],
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 9, color: Colors.white,
                        fontWeight: FontWeight.bold),
                  );
                }),
              )),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildChips() {
    const labels = ['Today', 'This Week', 'This Month', 'Custom'];
    return List.generate(4, (i) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(labels[i]),
        selected: _filterIdx == i,
        onSelected: (_) async {
          if (i == 3) await _pickRange();
          setState(() => _filterIdx = i);
        },
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: _filterIdx == i ? Colors.white : null,
          fontSize: 12,
        ),
      ),
    ));
  }

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (r != null) setState(() { _custom = r; _filterIdx = 3; });
  }

  List<BarChartGroupData> _barGroups(List<OrderModel> orders) {
    final statuses = ['pending', 'accepted', 'dispatched', 'delivered', 'cancelled'];
    return List.generate(statuses.length, (i) {
      final count = orders.where((o) => o.status == statuses[i]).length;
      final colors = [AppColors.pending, AppColors.accepted, AppColors.dispatched,
          AppColors.delivered, AppColors.cancelled];
      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: count.toDouble(), color: colors[i], width: 20, borderRadius: BorderRadius.circular(4)),
      ]);
    });
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
      Text(label, style: context.textTheme.bodySmall),
      Text(value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}
