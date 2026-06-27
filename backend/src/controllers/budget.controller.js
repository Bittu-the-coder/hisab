const Budget = require('../models/Budget');

exports.create = async (req, res, next) => {
  try {
    const { month, year, categories, alertAt } = req.body;
    const totalBudget = (categories || []).reduce((sum, c) => sum + c.limit, 0);
    const budget = await Budget.findOneAndUpdate(
      { user: req.user._id, month, year },
      { totalBudget, categories, alertAt },
      { upsert: true, new: true, runValidators: true }
    );
    res.status(201).json({ success: true, data: { budget } });
  } catch (error) {
    next(error);
  }
};

exports.get = async (req, res, next) => {
  try {
    const { month, year } = req.query;
    const budget = await Budget.findOne({ user: req.user._id, month, year });
    res.json({ success: true, data: { budget } });
  } catch (error) {
    next(error);
  }
};

exports.delete = async (req, res, next) => {
  try {
    const budget = await Budget.findOneAndDelete({ _id: req.params.id, user: req.user._id });
    if (!budget) {
      return res.status(404).json({ success: false, message: 'Budget not found' });
    }
    res.json({ success: true, data: { message: 'Budget deleted' } });
  } catch (error) {
    next(error);
  }
};

exports.update = async (req, res, next) => {
  try {
    const { categories, alertAt } = req.body;
    const totalBudget = (categories || []).reduce((sum, c) => sum + c.limit, 0);
    const budget = await Budget.findOneAndUpdate(
      { _id: req.params.id, user: req.user._id },
      { totalBudget, categories, alertAt },
      { new: true, runValidators: true }
    );
    if (!budget) {
      return res.status(404).json({ success: false, message: 'Budget not found' });
    }
    res.json({ success: true, data: { budget } });
  } catch (error) {
    next(error);
  }
};
