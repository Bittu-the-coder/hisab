const router = require('express').Router();
const auth = require('../middleware/auth');
const ctrl = require('../controllers/insights.controller');

router.use(auth);
router.get('/summary', ctrl.summary);
router.get('/category-breakdown', ctrl.categoryBreakdown);
router.get('/daily-log', ctrl.dailyLog);
router.get('/monthly-trend', ctrl.monthlyTrend);
router.get('/budget-status', ctrl.budgetStatus);

module.exports = router;
