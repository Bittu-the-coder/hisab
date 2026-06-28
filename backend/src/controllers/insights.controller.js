const Expense = require('../models/Expense');
const Budget = require('../models/Budget');

function debitMatch(userId, start, end) {
  return { user: userId, transactionType: 'debit', date: { $gte: start, $lt: end } };
}

exports.summary = async (req, res, next) => {
  try {
    const { month, year } = req.query;
    const m = Number(month), y = Number(year);
    const start = new Date(y, m - 1, 1);
    const end = new Date(y, m, 1);

    const [result, lastResult] = await Promise.all([
      Expense.aggregate([
        { $match: debitMatch(req.user._id, start, end) },
        { $group: { _id: null, total: { $sum: '$amount' }, count: { $sum: 1 } } }
      ]),
      Expense.aggregate([
        { $match: debitMatch(req.user._id, new Date(y, m - 2, 1), new Date(y, m - 1, 1)) },
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ])
    ]);

    const totalSpent = result[0]?.total || 0;
    const totalLastMonth = lastResult[0]?.total || 0;
    const expenseCount = result[0]?.count || 0;
    const percentageChange = totalLastMonth > 0
      ? +(((totalSpent - totalLastMonth) / totalLastMonth) * 100).toFixed(1)
      : 0;

    const topCat = await Expense.aggregate([
      { $match: debitMatch(req.user._id, start, end) },
      { $group: { _id: '$category', total: { $sum: '$amount' } } },
      { $sort: { total: -1 } },
      { $limit: 1 }
    ]);

    const daysInMonth = new Date(y, m, 0).getDate();
    const avgPerDay = +(totalSpent / daysInMonth).toFixed(0);

    res.json({
      success: true, data: {
        totalSpent, totalLastMonth, percentageChange,
        topCategory: topCat[0]?._id || 'other',
        expenseCount, avgPerDay
      }
    });
  } catch (error) {
    next(error);
  }
};

exports.categoryBreakdown = async (req, res, next) => {
  try {
    const { month, year } = req.query;
    const start = new Date(year, month - 1, 1);
    const end = new Date(year, month, 1);

    const breakdown = await Expense.aggregate([
      { $match: debitMatch(req.user._id, start, end) },
      { $group: { _id: '$category', total: { $sum: '$amount' }, count: { $sum: 1 } } },
      { $sort: { total: -1 } }
    ]);

    const grandTotal = breakdown.reduce((sum, b) => sum + b.total, 0);

    res.json({
      success: true, data: {
        breakdown: breakdown.map(b => ({
          category: b._id,
          total: b.total,
          percentage: grandTotal > 0 ? +((b.total / grandTotal) * 100).toFixed(1) : 0,
          count: b.count
        }))
      }
    });
  } catch (error) {
    next(error);
  }
};

exports.dailyLog = async (req, res, next) => {
  try {
    const { month, year } = req.query;
    const m = Number(month), y = Number(year);
    const start = new Date(y, m - 1, 1);
    const end = new Date(y, m, 1);

    const daily = await Expense.aggregate([
      { $match: debitMatch(req.user._id, start, end) },
      { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$date' } }, total: { $sum: '$amount' }, count: { $sum: 1 } } },
      { $sort: { _id: 1 } }
    ]);

    const dailyMap = {};
    for (const d of daily) dailyMap[d._id] = { total: d.total, count: d.count };

    const daysInMonth = new Date(y, m, 0).getDate();
    const result = [];
    for (let d = 1; d <= daysInMonth; d++) {
      const dateStr = `${y}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
      result.push({
        date: dateStr,
        total: dailyMap[dateStr]?.total || 0,
        count: dailyMap[dateStr]?.count || 0
      });
    }

    res.json({ success: true, data: { daily: result } });
  } catch (error) {
    next(error);
  }
};

exports.monthlyTrend = async (req, res, next) => {
  try {
    const months = Number(req.query.months) || 6;
    const now = new Date();
    const results = [];

    for (let i = months - 1; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const m = d.getMonth() + 1;
      const y = d.getFullYear();
      const start = new Date(y, m - 1, 1);
      const end = new Date(y, m, 1);

      const [spendResult, budget] = await Promise.all([
        Expense.aggregate([
          { $match: debitMatch(req.user._id, start, end) },
          { $group: { _id: null, total: { $sum: '$amount' } } }
        ]),
        Budget.findOne({ user: req.user._id, month: m, year: y })
      ]);

      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      results.push({
        month: `${monthNames[m - 1]} ${y}`,
        total: spendResult[0]?.total || 0,
        budget: budget?.totalBudget || 0
      });
    }

    res.json({ success: true, data: { trend: results } });
  } catch (error) {
    next(error);
  }
};

exports.budgetStatus = async (req, res, next) => {
  try {
    const { month, year } = req.query;
    const m = Number(month), y = Number(year);
    const start = new Date(y, m - 1, 1);
    const end = new Date(y, m, 1);

    const [budget, spendResult] = await Promise.all([
      Budget.findOne({ user: req.user._id, month: m, year: y }),
      Expense.aggregate([
        { $match: debitMatch(req.user._id, start, end) },
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ])
    ]);

    if (!budget) {
      return res.json({ success: true, data: null });
    }

    const totalSpent = spendResult[0]?.total || 0;
    const percentUsed = +((totalSpent / budget.totalBudget) * 100).toFixed(1);

    const breakdown = await Expense.aggregate([
      { $match: debitMatch(req.user._id, start, end) },
      { $group: { _id: '$category', total: { $sum: '$amount' } } }
    ]);

    const spentMap = {};
    for (const b of breakdown) spentMap[b._id] = b.total;

    res.json({
      success: true, data: {
        totalBudget: budget.totalBudget,
        totalSpent,
        percentUsed,
        isAlertTriggered: percentUsed >= budget.alertAt,
        remaining: Math.max(0, budget.totalBudget - totalSpent),
        categories: budget.categories.map(cat => ({
          category: cat.category,
          limit: cat.limit,
          spent: spentMap[cat.category] || 0,
          percentUsed: +(((spentMap[cat.category] || 0) / cat.limit) * 100).toFixed(1),
          isOver: (spentMap[cat.category] || 0) > cat.limit
        }))
      }
    });
  } catch (error) {
    next(error);
  }
};
