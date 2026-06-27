const Expense = require('../models/Expense');
const Budget  = require('../models/Budget');

async function checkBudgetAlert(userId, month, year) {
  const budget = await Budget.findOne({ user: userId, month, year });
  if (!budget) return null;

  const start = new Date(year, month - 1, 1);
  const end   = new Date(year, month, 1);

  const result = await Expense.aggregate([
    { $match: { user: userId, date: { $gte: start, $lt: end } } },
    { $group: { _id: null, total: { $sum: '$amount' } } }
  ]);

  const totalSpent = result[0]?.total || 0;
  const percentUsed = (totalSpent / budget.totalBudget) * 100;

  if (percentUsed >= budget.alertAt) {
    return {
      triggered: true,
      percentUsed: +percentUsed.toFixed(1),
      totalSpent,
      totalBudget: budget.totalBudget,
      remaining: Math.max(0, budget.totalBudget - totalSpent)
    };
  }

  return { triggered: false, percentUsed: +percentUsed.toFixed(1) };
}

async function checkCategoryBudgets(userId, month, year) {
  const budget = await Budget.findOne({ user: userId, month, year });
  if (!budget || !budget.categories.length) return [];

  const start = new Date(year, month - 1, 1);
  const end   = new Date(year, month, 1);

  const breakdown = await Expense.aggregate([
    { $match: { user: userId, date: { $gte: start, $lt: end } } },
    { $group: { _id: '$category', total: { $sum: '$amount' } } }
  ]);

  const spentMap = {};
  for (const b of breakdown) spentMap[b._id] = b.total;

  return budget.categories.map(cat => ({
    category:   cat.category,
    limit:      cat.limit,
    spent:      spentMap[cat.category] || 0,
    isOver:     (spentMap[cat.category] || 0) > cat.limit,
    percentUsed: +(((spentMap[cat.category] || 0) / cat.limit) * 100).toFixed(1)
  }));
}

module.exports = { checkBudgetAlert, checkCategoryBudgets };
