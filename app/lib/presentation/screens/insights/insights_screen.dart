import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../providers/insights_provider.dart';
import '../../../data/models/insight_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../providers/auth_provider.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool _showPie = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
      _focusedDay = DateTime(_year, _month, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
      _focusedDay = DateTime(_year, _month, 1);
    });
  }

  IconData _catIcon(String cat) {
    const icons = {
      'food': Icons.restaurant, 'transport': Icons.directions_car,
      'shopping': Icons.shopping_bag, 'entertainment': Icons.movie,
      'health': Icons.local_hospital, 'education': Icons.school,
      'utilities': Icons.bolt, 'rent': Icons.home,
      'groceries': Icons.local_grocery_store, 'personal_care': Icons.face,
      'travel': Icons.flight, 'other': Icons.more_horiz,
    };
    return icons[cat] ?? Icons.more_horiz;
  }

  String _capitalize(String value) {
    return value.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return '';
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(DateTime(_year, _month));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _prevMonth,
                  ),
                  Text(
                    monthLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                indicatorColor: Theme.of(context).colorScheme.secondary,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Categories'),
                  Tab(text: 'Daily Log'),
                  Tab(text: 'Trend'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverview(),
          _buildCategories(),
          _buildDailyLog(),
          _buildTrend(),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    final summaryAsync = ref.watch(
      insightSummaryProvider((month: _month, year: _year)),
    );
    final budgetAsync = ref.watch(
      budgetStatusProvider((month: _month, year: _year)),
    );
    final breakdownAsync = ref.watch(
      categoryBreakdownProvider((month: _month, year: _year)),
    );

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (summary) {
        final budget = budgetAsync.valueOrNull;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _summaryCard(summary),
            if (budget != null) ...[
              const SizedBox(height: 16),
              _budgetCard(budget),
            ],
            const SizedBox(height: 16),
            _topCategoriesCard(breakdownAsync),
            const SizedBox(height: 16),
            _avgCard(summary),
          ],
        );
      },
    );
  }

  Widget _summaryCard(InsightSummary summary) {
    final isUp = summary.percentageChange >= 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Spent',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(summary.totalSpent),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isUp ? Icons.trending_up : Icons.trending_down,
                  size: 18,
                  color: isUp ? AppColors.negative : AppColors.accent,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isUp ? '+' : ''}${summary.percentageChange.toStringAsFixed(1)}% vs last month',
                  style: TextStyle(
                    color: isUp ? AppColors.negative : AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Top category: ${_capitalize(summary.topCategory)}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
            Text(
              '${summary.expenseCount} expenses this month',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _budgetCard(BudgetStatus budget) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget vs Actual',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(CurrencyFormatter.format(budget.totalSpent)),
                Text(CurrencyFormatter.format(budget.totalBudget)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: budget.totalBudget > 0
                    ? (budget.totalSpent / budget.totalBudget).clamp(0.0, 1.0)
                    : 0,
                backgroundColor: Theme.of(context).dividerTheme.color ?? AppColors.divider,
                valueColor: AlwaysStoppedAnimation(
                  budget.isAlertTriggered
                      ? AppColors.negative
                      : AppColors.secondary,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${budget.percentUsed.toStringAsFixed(0)}% used - ${CurrencyFormatter.format(budget.remaining)} remaining',
              style: TextStyle(
                color: budget.isAlertTriggered
                    ? AppColors.negative
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topCategoriesCard(
    AsyncValue<List<CategoryBreakdown>> breakdownAsync,
  ) {
    return breakdownAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('$e'),
        ),
      ),
      data: (breakdown) {
        final sorted = [...breakdown]
          ..sort((a, b) => b.total.compareTo(a.total));
        final top = sorted.take(3).toList();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                'Top Categories',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
                const SizedBox(height: 12),
                ...List.generate(top.length, (i) {
                  final item = top[i];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i < top.length - 1 ? 12 : 0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.categoryColors[item.category] ??
                                AppColors.categoryColors['other']!,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _capitalize(item.category),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${item.count} entries',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(item.total),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _avgCard(InsightSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.secondary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(
              'Average per day',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
                Text(
                  CurrencyFormatter.format(summary.avgPerDay.toInt()),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final breakdownAsync = ref.watch(
      categoryBreakdownProvider((month: _month, year: _year)),
    );

    return breakdownAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (breakdown) {
        if (breakdown.isEmpty) {
          return const Center(child: Text('No data'));
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.pie_chart),
                        label: Text('Pie'),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.bar_chart),
                        label: Text('Bar'),
                      ),
                    ],
                    selected: {_showPie},
                    onSelectionChanged: (v) =>
                        setState(() => _showPie = v.first),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _showPie ? _pieChart(breakdown) : _barChart(breakdown),
            ),
          ],
        );
      },
    );
  }

  Widget _pieChart(List<CategoryBreakdown> breakdown) {
    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: List.generate(breakdown.length, (i) {
                final item = breakdown[i];
                return PieChartSectionData(
                  color: AppColors.categoryColors[item.category] ??
                      AppColors.categoryColors['other']!,
                  value: item.percentage,
                  title: '${item.percentage.toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: breakdown.map((item) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.categoryColors[item.category] ??
                          AppColors.categoryColors['other']!,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_capitalize(item.category)}: ${CurrencyFormatter.format(item.total)} (${item.percentage.toStringAsFixed(1)}%)',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _barChart(List<CategoryBreakdown> breakdown) {
    final maxY =
        breakdown.fold<double>(0, (m, b) => m > b.total ? m : b.total.toDouble());
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = breakdown[groupIndex];
                return BarTooltipItem(
                  '${_capitalize(item.category)}\n${CurrencyFormatter.format(item.total)}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= breakdown.length) {
                    return const SizedBox();
                  }
                  final label = _capitalize(breakdown[idx].category);
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      label.length > 4
                          ? '${label.substring(0, 4)}.'
                          : label,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  return Text(
                    CurrencyFormatter.formatWithoutSymbol(value.toInt()),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          barGroups: List.generate(breakdown.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: breakdown[i].total.toDouble(),
                  color: AppColors.categoryColors[breakdown[i].category] ??
                      AppColors.categoryColors['other']!,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Future<List<ExpenseModel>> _fetchDayExpenses(String dateStr) async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getExpensesByDate(dateStr);
      return (data['expenses'] as List)
          .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Widget _buildDailyLog() {
    final dailyLogAsync = ref.watch(
      dailyLogProvider((month: _month, year: _year)),
    );

    return dailyLogAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (entries) {
        final logMap = <String, DailyLogEntry>{};
        for (final e in entries) {
          logMap[e.date] = e;
        }
        final selectedDateStr = DateHelpers.apiDate(_selectedDay);
        final selectedEntry = logMap[selectedDateStr];

        return ListView(
          children: [
            TableCalendar(
              firstDay: DateTime(_year, _month, 1),
              lastDay: DateTime(_year, _month + 1, 0),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focused) {
                  final dayStr = DateHelpers.apiDate(day);
                  final entry = logMap[dayStr];
                  final hasExpense = entry != null && entry.total > 0;
                  return Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: hasExpense ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : null,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 14,
                        color: hasExpense ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  );
                },
                todayBuilder: (context, day, focused) {
                  final dayStr = DateHelpers.apiDate(day);
                  final entry = logMap[dayStr];
                  final hasExpense = entry != null && entry.total > 0;
                  return Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: hasExpense ? Theme.of(context).colorScheme.primary : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hasExpense
                            ? Colors.white
                            : Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  );
                },
                selectedBuilder: (context, day, focused) {
                  return Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(DateHelpers.format(_selectedDay)),
              subtitle: Text(
                selectedEntry != null
                    ? '${selectedEntry.count} expenses'
                    : 'No expenses',
              ),
              trailing: selectedEntry != null
                  ? Text(
                      CurrencyFormatter.format(selectedEntry.total),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            if (selectedEntry != null)
              FutureBuilder<List<ExpenseModel>>(
                future: _fetchDayExpenses(selectedDateStr),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  if (snap.data == null || snap.data!.isEmpty) {
                    return const SizedBox();
                  }
                  return Column(
                    children: snap.data!.map((e) => Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.categoryColors[e.category]?.withOpacity(0.2) ?? Colors.grey[200],
                          child: Icon(
                            _catIcon(e.category),
                            size: 18,
                            color: AppColors.categoryColors[e.category],
                          ),
                        ),
                        title: Text(e.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: Text(e.category.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '), style: const TextStyle(fontSize: 11)),
                        trailing: Text(CurrencyFormatter.format(e.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    )).toList(),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildTrend() {
    final trendAsync = ref.watch(monthlyTrendProvider(6));

    return trendAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (trends) {
        if (trends.isEmpty) {
          return const Center(child: Text('No trend data'));
        }
        final maxVal = trends.fold<double>(0, (m, t) {
          final val = t.total > t.budget ? t.total : t.budget;
          return m > val ? m : val.toDouble();
        });
        final maxY = maxVal < 100 ? 100.0 : maxVal * 1.2;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= trends.length) {
                        return const SizedBox();
                      }
                      final parts = trends[idx].month.split('-');
                      final label =
                          parts.length >= 2 ? parts[1] : trends[idx].month;
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        CurrencyFormatter.formatWithoutSymbol(value.toInt()),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final idx = spot.x.toInt();
                      final trend =
                          idx < trends.length ? trends[idx] : null;
                      final isBudget = spot.barIndex == 1;
                      final label = isBudget ? 'Budget' : 'Spent';
                      return LineTooltipItem(
                        '${trend?.month ?? ''}\n$label: ${CurrencyFormatter.format(spot.y.toInt())}',
                        TextStyle(
                          color: isBudget
                              ? AppColors.warning
                              : AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    trends.length,
                    (i) => FlSpot(i.toDouble(), trends[i].total.toDouble()),
                  ),
                  isCurved: false,
                  color: AppColors.primary,
                  barWidth: 2.5,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(show: false),
                ),
                LineChartBarData(
                  spots: List.generate(
                    trends.length,
                    (i) => FlSpot(i.toDouble(), trends[i].budget.toDouble()),
                  ),
                  isCurved: false,
                  color: AppColors.warning,
                  barWidth: 2,
                  dashArray: [6, 4],
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
