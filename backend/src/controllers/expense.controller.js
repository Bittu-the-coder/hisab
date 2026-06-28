const Expense = require('../models/Expense');
const User = require('../models/User');
const { checkBudgetAlert } = require('../services/budgetChecker');

const ONLINE_MODES = ['upi', 'card', 'netbanking', 'net_banking', 'other'];

exports.create = async (req, res, next) => {
  try {
    const { title, amount, category, date, note, paymentMode, transactionType, tags, groupId } = req.body;
    const type = transactionType || 'debit';
    const expense = await Expense.create({
      user: req.user._id, title, amount, category,
      date, note, paymentMode, transactionType: type, tags, groupId
    });
    const isOnline = ONLINE_MODES.includes(paymentMode);
    const balanceField = isOnline ? 'onlineBalance' : 'cashBalance';
    const change = type === 'credit' ? amount : -amount;
    await User.findByIdAndUpdate(req.user._id, { $inc: { [balanceField]: change } });
    req.user[balanceField] += change;
    if (groupId) {
      const GroupExpense = require('../models/GroupExpense');
      await GroupExpense.create({
        group: groupId, title, amount, category,
        paidBy: req.user._id, splits: [], date, note,
        expenseRef: expense._id
      });
    }
    if (type === 'debit') {
      const dt = expense.date;
      const budgetAlert = await checkBudgetAlert(req.user._id, dt.getMonth() + 1, dt.getFullYear());
      return res.status(201).json({ success: true, data: { expense, budgetAlert } });
    }
    res.status(201).json({ success: true, data: { expense, budgetAlert: null } });
  } catch (error) {
    next(error);
  }
};

exports.list = async (req, res, next) => {
  try {
    const { month, year, category, page = 1, limit = 20, search, date } = req.query;
    const filter = { user: req.user._id };

    if (date) {
      const d = new Date(date);
      const start = new Date(d.getFullYear(), d.getMonth(), d.getDate());
      const end = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1);
      filter.date = { $gte: start, $lt: end };
    } else if (month && year) {
      const start = new Date(year, month - 1, 1);
      const end = new Date(year, month, 1);
      filter.date = { $gte: start, $lt: end };
    }
    if (category) filter.category = category;
    if (search) {
      filter.$or = [
        { title: { $regex: search, $options: 'i' } },
        { note: { $regex: search, $options: 'i' } }
      ];
    }

    const skip = (page - 1) * limit;
    const [expenses, total] = await Promise.all([
      Expense.find(filter).sort({ date: -1 }).skip(skip).limit(Number(limit)),
      Expense.countDocuments(filter)
    ]);

    const amountResult = await Expense.aggregate([
      { $match: filter },
      { $group: { _id: null, total: { $sum: '$amount' } } }
    ]);
    const totalAmount = amountResult[0]?.total || 0;

    res.json({
      success: true,
      data: {
        expenses,
        total,
        page: Number(page),
        pages: Math.ceil(total / limit),
        totalAmount
      }
    });
  } catch (error) {
    next(error);
  }
};

exports.get = async (req, res, next) => {
  try {
    const expense = await Expense.findOne({ _id: req.params.id, user: req.user._id });
    if (!expense) {
      return res.status(404).json({ success: false, message: 'Expense not found' });
    }
    res.json({ success: true, data: { expense } });
  } catch (error) {
    next(error);
  }
};

exports.update = async (req, res, next) => {
  try {
    const { title, amount, category, date, note, paymentMode, transactionType, tags } = req.body;
    const old = await Expense.findOne({ _id: req.params.id, user: req.user._id });
    if (!old) {
      return res.status(404).json({ success: false, message: 'Expense not found' });
    }
    const newAmount = amount ?? old.amount;
    const newMode = paymentMode ?? old.paymentMode;
    const newType = transactionType ?? old.transactionType;
    const oldIsOnline = ONLINE_MODES.includes(old.paymentMode);
    const newIsOnline = ONLINE_MODES.includes(newMode);
    if (oldIsOnline !== newIsOnline || old.amount !== newAmount || old.transactionType !== newType) {
      const reverseField = oldIsOnline ? 'onlineBalance' : 'cashBalance';
      const reverseChange = old.transactionType === 'credit' ? -old.amount : old.amount;
      await User.findByIdAndUpdate(req.user._id, { $inc: { [reverseField]: reverseChange } });
      req.user[reverseField] += reverseChange;
      const applyField = newIsOnline ? 'onlineBalance' : 'cashBalance';
      const applyChange = newType === 'credit' ? newAmount : -newAmount;
      await User.findByIdAndUpdate(req.user._id, { $inc: { [applyField]: applyChange } });
      req.user[applyField] += applyChange;
    }
    const expense = await Expense.findOneAndUpdate(
      { _id: req.params.id, user: req.user._id },
      { title, amount, category, date, note, paymentMode, transactionType, tags },
      { new: true, runValidators: true }
    );
    res.json({ success: true, data: { expense } });
  } catch (error) {
    next(error);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const expense = await Expense.findOneAndDelete({ _id: req.params.id, user: req.user._id });
    if (!expense) {
      return res.status(404).json({ success: false, message: 'Expense not found' });
    }
    const isOnline = ONLINE_MODES.includes(expense.paymentMode);
    const balanceField = isOnline ? 'onlineBalance' : 'cashBalance';
    const change = expense.transactionType === 'credit' ? -expense.amount : expense.amount;
    await User.findByIdAndUpdate(req.user._id, { $inc: { [balanceField]: change } });
    req.user[balanceField] += change;
    if (expense.groupId) {
      const GroupExpense = require('../models/GroupExpense');
      await GroupExpense.deleteMany({ expenseRef: expense._id });
    }
    res.json({ success: true, data: { message: 'Expense deleted' } });
  } catch (error) {
    next(error);
  }
};
