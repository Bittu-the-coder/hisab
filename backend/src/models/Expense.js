const mongoose = require('mongoose');

const CATEGORIES = [
  'food', 'transport', 'shopping', 'entertainment',
  'health', 'education', 'utilities', 'rent',
  'groceries', 'personal_care', 'travel', 'other'
];

const expenseSchema = new mongoose.Schema({
  user:        { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title:       { type: String, required: true, trim: true },
  amount:      { type: Number, required: true, min: 1 },
  category:    { type: String, enum: CATEGORIES, default: 'other' },
  date:        { type: Date, default: Date.now },
  note:        { type: String, default: '', trim: true },
  paymentMode: { type: String, enum: ['cash', 'upi', 'card', 'netbanking', 'other'], default: 'upi' },
  tags:        [{ type: String }],
  isRecurring: { type: Boolean, default: false },
  groupId:     { type: mongoose.Schema.Types.ObjectId, ref: 'Group', default: null }
}, { timestamps: true });

expenseSchema.index({ user: 1, date: -1 });
expenseSchema.index({ user: 1, category: 1 });

module.exports = mongoose.model('Expense', expenseSchema);
module.exports.CATEGORIES = CATEGORIES;
