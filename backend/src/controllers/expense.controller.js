const Expense = require('../models/Expense');
const { checkBudgetAlert } = require('../services/budgetChecker');

exports.create = async (req, res, next) => {
  try {
    const { title, amount, category, date, note, paymentMode, tags, groupId } = req.body;
    const expense = await Expense.create({
      user: req.user._id, title, amount, category,
      date, note, paymentMode, tags, groupId
    });
    if (groupId) {
      const GroupExpense = require('../models/GroupExpense');
      await GroupExpense.create({
        group: groupId, title, amount, category,
        paidBy: req.user._id, splits: [], date, note,
        expenseRef: expense._id
      });
    }
    const dt = expense.date;
    const budgetAlert = await checkBudgetAlert(req.user._id, dt.getMonth() + 1, dt.getFullYear());
    res.status(201).json({ success: true, data: { expense, budgetAlert } });
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
    const { title, amount, category, date, note, paymentMode, tags } = req.body;
    const expense = await Expense.findOneAndUpdate(
      { _id: req.params.id, user: req.user._id },
      { title, amount, category, date, note, paymentMode, tags },
      { new: true, runValidators: true }
    );
    if (!expense) {
      return res.status(404).json({ success: false, message: 'Expense not found' });
    }
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
    if (expense.groupId) {
      const GroupExpense = require('../models/GroupExpense');
      await GroupExpense.deleteMany({ expenseRef: expense._id });
    }
    res.json({ success: true, data: { message: 'Expense deleted' } });
  } catch (error) {
    next(error);
  }
};
