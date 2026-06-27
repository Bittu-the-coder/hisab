const Group = require('../models/Group');
const GroupExpense = require('../models/GroupExpense');
const User = require('../models/User');
const { simplifyDebts } = require('../services/debtSimplifier');

exports.create = async (req, res, next) => {
  try {
    const { name, icon } = req.body;
    const group = await Group.create({
      name, icon: icon || 'group',
      members: [req.user._id],
      admins: [req.user._id],
      createdBy: req.user._id
    });
    res.status(201).json({ success: true, data: { group } });
  } catch (error) {
    next(error);
  }
};

exports.list = async (req, res, next) => {
  try {
    const groups = await Group.find({ members: req.user._id })
      .populate('members', 'name email avatar');
    res.json({ success: true, data: { groups } });
  } catch (error) {
    next(error);
  }
};

exports.get = async (req, res, next) => {
  try {
    const group = await Group.findOne({ _id: req.params.id, members: req.user._id })
      .populate('members', 'name email avatar');
    if (!group) {
      return res.status(404).json({ success: false, message: 'Group not found' });
    }
    const rawExpenses = await GroupExpense.find({ group: group._id })
      .populate('paidBy', 'name email')
      .populate('splits.user', 'name email')
      .sort({ date: -1 });
    const expenses = rawExpenses.map(e => {
      const obj = e.toObject();
      obj.user = (e.paidBy && typeof e.paidBy === 'object' ? e.paidBy._id?.toString() : e.paidBy?.toString()) || '';
      obj.expenseRef = e.expenseRef?.toString() || '';
      return obj;
    });
    const balances = await exports.getBalances(req, res, next, true);
    res.json({ success: true, data: { group, members: group.members, expenses, balances } });
  } catch (error) {
    next(error);
  }
};

exports.join = async (req, res, next) => {
  try {
    const { inviteCode } = req.body;
    const group = await Group.findOne({ inviteCode: inviteCode?.toUpperCase() });
    if (!group) {
      return res.status(404).json({ success: false, message: 'Invalid invite code' });
    }
    if (group.members.includes(req.user._id)) {
      return res.status(400).json({ success: false, message: 'Already a member' });
    }
    group.members.push(req.user._id);
    await group.save();
    res.json({ success: true, data: { group } });
  } catch (error) {
    next(error);
  }
};

exports.update = async (req, res, next) => {
  try {
    const { name, icon } = req.body;
    const group = await Group.findOneAndUpdate(
      { _id: req.params.id, admins: req.user._id },
      { name, icon },
      { new: true, runValidators: true }
    ).populate('members', 'name email avatar');
    if (!group) {
      return res.status(404).json({ success: false, message: 'Group not found or not authorized' });
    }
    res.json({ success: true, data: { group } });
  } catch (error) {
    next(error);
  }
};

exports.delete = async (req, res, next) => {
  try {
    const group = await Group.findOneAndDelete({ _id: req.params.id, admins: req.user._id });
    if (!group) {
      return res.status(404).json({ success: false, message: 'Group not found or not authorized' });
    }
    await GroupExpense.deleteMany({ group: group._id });
    res.json({ success: true, data: { message: 'Group deleted' } });
  } catch (error) {
    next(error);
  }
};

exports.addGroupExpense = async (req, res, next) => {
  try {
    const group = await Group.findOne({ _id: req.params.id, members: req.user._id });
    if (!group) {
      return res.status(404).json({ success: false, message: 'Group not found' });
    }
    const { title, amount, category, paidBy, splits, date, note } = req.body;
    const expense = await GroupExpense.create({
      group: group._id, title, amount, category, paidBy, splits, date, note
    });
    res.status(201).json({ success: true, data: { expense } });
  } catch (error) {
    next(error);
  }
};

exports.listGroupExpenses = async (req, res, next) => {
  try {
    const group = await Group.findOne({ _id: req.params.id, members: req.user._id });
    if (!group) {
      return res.status(404).json({ success: false, message: 'Group not found' });
    }
    const expenses = await GroupExpense.find({ group: group._id })
      .populate('paidBy', 'name email')
      .populate('splits.user', 'name email')
      .sort({ date: -1 });
    res.json({ success: true, data: { expenses } });
  } catch (error) {
    next(error);
  }
};

exports.getBalances = async (req, res, next, internal = false) => {
  try {
    const group = await Group.findOne({ _id: req.params.id, members: req.user._id });
    if (!group) {
      if (internal) return [];
      return res.status(404).json({ success: false, message: 'Group not found' });
    }

    const expenses = await GroupExpense.find({ group: group._id });
    const netBalances = {};

    for (const member of group.members) {
      netBalances[member.toString()] = 0;
    }

    for (const expense of expenses) {
      const payer = expense.paidBy.toString();
      netBalances[payer] += expense.amount;
      for (const split of expense.splits) {
        const user = split.user.toString();
        netBalances[user] -= split.amount;
      }
    }

    const balanceArray = Object.entries(netBalances)
      .filter(([_, net]) => Math.abs(net) > 0)
      .map(([userId, net]) => ({ userId, net }));

    const settlements = simplifyDebts(balanceArray);

    const populatedSettlements = await Promise.all(
      settlements.map(async (s) => {
        const [fromUser, toUser] = await Promise.all([
          User.findById(s.from).select('name email'),
          User.findById(s.to).select('name email')
        ]);
        return {
          from: { id: s.from, name: fromUser?.name, email: fromUser?.email },
          to: { id: s.to, name: toUser?.name, email: toUser?.email },
          amount: s.amount
        };
      })
    );

    if (internal) return populatedSettlements;
    res.json({ success: true, data: { balances: populatedSettlements } });
  } catch (error) {
    if (internal) return [];
    next(error);
  }
};
