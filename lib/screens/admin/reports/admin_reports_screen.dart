import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../models/order_model.dart';
import '../../../providers/orders_provider.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});
  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  int _filterIdx = 2; // default: this month
  DateTimeRange? _custom;

  DateRange get _range {
    final now   = DateTime.now();
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
    final allOrders = ref.watch(allOrdersProvider).asData?.value ?? [];
    final r         = _range;

    final filtered = allOrders.where((o) =>
        o.createdAt.isAfter(r.from.subtract(const Duration(seconds: 1))) &&
        o.createdAt.isBefore(r.to.add(const Duration(seconds: 1)))).toList();

    final total     = filtered.length;
    final delivered = filtered.where((o) => o.status == 'delivered').length;
    final pending   = filtered.where((o) => o.status == 'pending').length;

    // Top products
    final productMap = <String, int>{};
    for (final o in filtered) {
      for (final item in o.items) {
        productMap[item.productName] =
            (productMap[item.productName] ?? 0) + item.quantity;
      }
    }
    final topProducts = (productMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .toList();

    // Top shops
    final shopMap = <String, int>{};
    for (final o in filtered) {
      shopMap[o.shopName] = (shopMap[o.shopName] ?? 0) + 1;
    }
    final topShops = (shopMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .toList();

    // Monthly trend (last 6 months)
    final monthlyCounts = <int>[];
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(DateTime.now().year, DateTime.now().month - i, 1);
      final count = allOrders.where((o) =>
          o.createdAt.year == date.year &&
          o.createdAt.month == date.month).length;
      monthlyCounts.add(count);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              ..._chips(),
              if (_filterIdx == 3)
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_custom != null
                      ? '${_custom!.start.display} – ${_custom!.end.display}'
                      : 'Pick Range'),
                  onPressed: _pickRange,
                ),
            ]),
          ),
          const SizedBox(height: 16),

          // Summary
          Row(children: [
            Expanded(child: _Card('Total Orders', '$total',     AppColors.info)),
            const SizedBox(width: 10),
            Expanded(child: _Card('Delivered',    '$delivered', AppColors.success)),
            const SizedBox(width: 10),
            Expanded(child: _Card('Pending',      '$pending',   AppColors.warning)),
          ]),
          const SizedBox(height: 24),

          // Monthly line chart
          Text('Monthly Trend (6 months)', style: context.textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: LineChart(LineChartData(
              minY: 0,
              maxY: (monthlyCounts.reduce((a, b) => a > b ? a : b) * 1.4 + 1).toDouble(),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final month = DateTime.now().month - (5 - v.toInt());
                      final names = ['Jan','Feb','Mar','Apr','May','Jun',
                          'Jul','Aug','Sep','Oct','Nov','Dec'];
                      final idx = ((month - 1) % 12 + 12) % 12;
                      return Text(names[idx], style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(6,
                      (i) => FlSpot(i.toDouble(), monthlyCounts[i].toDouble())),
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
              ],
            )),
          ),
          const SizedBox(height: 24),

          // Status pie chart
          if (total > 0) ...[
            Text('Orders by Status', style: context.textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PieChart(PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 44,
                sections: _pieData(filtered),
              )),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12, runSpacing: 6,
              children: _legend(),
            ),
            const SizedBox(height: 24),
          ],

          // Top products
          if (topProducts.isNotEmpty) ...[
            Text('Top Products by Quantity', style: context.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...topProducts.map((e) => _RankRow(
                rank: topProducts.indexOf(e) + 1,
                label: e.key,
                value: '${e.value} units')),
            const SizedBox(height: 24),
          ],

          // Top shops
          if (topShops.isNotEmpty) ...[
            Text('Top Shops by Orders', style: context.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...topShops.map((e) => _RankRow(
                rank: topShops.indexOf(e) + 1,
                label: e.key,
                value: '${e.value} orders')),
          ],
        ],
      ),
    );
  }

  List<Widget> _chips() {
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
        labelStyle: TextStyle(color: _filterIdx == i ? Colors.white : null, fontSize: 12),
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
            colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (r != null) setState(() { _custom = r; _filterIdx = 3; });
  }

  List<PieChartSectionData> _pieData(List<OrderModel> orders) {
    final statuses = ['pending', 'accepted', 'processing', 'dispatched', 'delivered', 'cancelled'];
    final colors   = [AppColors.pending, AppColors.accepted, AppColors.processing,
        AppColors.dispatched, AppColors.delivered, AppColors.cancelled];
    final result = <PieChartSectionData>[];
    for (int i = 0; i < statuses.length; i++) {
      final count = orders.where((o) => o.status == statuses[i]).length;
      if (count == 0) continue;
      result.add(PieChartSectionData(
        value: count.toDouble(),
        color: colors[i],
        radius: 60,
        title: '$count',
        titleStyle: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.bold, fontSize: 12),
      ));
    }
    return result;
  }

  List<Widget> _legend() {
    final statuses = ['pending','accepted','processing','dispatched','delivered','cancelled'];
    final colors   = [AppColors.pending, AppColors.accepted, AppColors.processing,
        AppColors.dispatched, AppColors.delivered, AppColors.cancelled];
    return List.generate(statuses.length, (i) => Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(
          color: colors[i], shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(statuses[i], style: const TextStyle(fontSize: 11)),
    ]));
  }
}

class _Card extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _Card(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall),
      const SizedBox(height: 6),
      Text(value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}

class _RankRow extends StatelessWidget {
  final int    rank;
  final String label, value;
  const _RankRow({required this.rank, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.warning, AppColors.textSecondary, AppColors.accent];
    final rankColor = rank <= 3 ? colors[rank - 1] : AppColors.textSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: rankColor.withValues(alpha: 0.15),
          child: Text('#$rank', style: TextStyle(fontSize: 11,
              fontWeight: FontWeight.bold, color: rankColor)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
        Text(value, style: TextStyle(color: AppColors.primary,
            fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }
}
