const mongoose = require('mongoose');

const splitSchema = new mongoose.Schema({
  user:   { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  amount: { type: Number, required: true },
  isPaid: { type: Boolean, default: false }
});

const groupExpenseSchema = new mongoose.Schema({
  group:      { type: mongoose.Schema.Types.ObjectId, ref: 'Group', required: true },
  title:      { type: String, required: true, trim: true },
  amount:     { type: Number, required: true },
  category:   { type: String, default: 'other' },
  paidBy:     { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  splits:     [splitSchema],
  date:       { type: Date, default: Date.now },
  note:       { type: String, default: '' },
  expenseRef: { type: mongoose.Schema.Types.ObjectId, ref: 'Expense', default: null }
}, { timestamps: true });

module.exports = mongoose.model('GroupExpense', groupExpenseSchema);
