const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const connectDB = require('./config/db');
require('dotenv').config();

connectDB();

const app = express();

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

app.use('/api/auth', require('./routes/auth.routes'));
app.use('/api/expenses', require('./routes/expense.routes'));
app.use('/api/budgets', require('./routes/budget.routes'));
app.use('/api/insights', require('./routes/insights.routes'));
app.use('/api/groups', require('./routes/group.routes'));
app.use('/api/users', require('./routes/user.routes'));

app.get('/', (req, res) => res.json({ message: 'Hisab API running' }));
app.use(require('./middleware/errorHandler'));

const PORT = process.env.PORT || 5000;
if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => console.log(`Server on port ${PORT}`));
}
module.exports = app;
