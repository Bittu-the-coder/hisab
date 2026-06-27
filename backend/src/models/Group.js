const mongoose = require('mongoose');

const groupSchema = new mongoose.Schema({
  name:       { type: String, required: true, trim: true },
  icon:       { type: String, default: 'group' },
  members:    [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  admins:     [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  createdBy:  { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  inviteCode: { type: String, unique: true }
}, { timestamps: true });

groupSchema.pre('save', function() {
  if (!this.inviteCode) {
    this.inviteCode = Math.random().toString(36).substring(2, 8).toUpperCase();
  }
});

module.exports = mongoose.model('Group', groupSchema);
