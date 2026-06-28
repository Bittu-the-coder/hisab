const User = require('../models/User');

exports.getMe = async (req, res, next) => {
  try {
    res.json({ success: true, data: { user: req.user } });
  } catch (error) {
    next(error);
  }
};

exports.updateMe = async (req, res, next) => {
  try {
    const { name, avatar } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { name, avatar },
      { new: true, runValidators: true }
    );
    res.json({ success: true, data: { user } });
  } catch (error) {
    next(error);
  }
};

exports.getBalance = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id).select('cashBalance onlineBalance');
    res.json({ success: true, data: { cashBalance: user.cashBalance, onlineBalance: user.onlineBalance } });
  } catch (error) {
    next(error);
  }
};

exports.updateBalance = async (req, res, next) => {
  try {
    const { cashBalance, onlineBalance } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { cashBalance, onlineBalance },
      { new: true, select: 'cashBalance onlineBalance' }
    );
    res.json({ success: true, data: { cashBalance: user.cashBalance, onlineBalance: user.onlineBalance } });
  } catch (error) {
    next(error);
  }
};
