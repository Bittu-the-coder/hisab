const router = require('express').Router();
const auth = require('../middleware/auth');
const ctrl = require('../controllers/group.controller');

router.use(auth);
router.post('/', ctrl.create);
router.get('/', ctrl.list);
router.post('/join', ctrl.join);
router.get('/:id', ctrl.get);
router.put('/:id', ctrl.update);
router.delete('/:id', ctrl.delete);
router.post('/:id/expenses', ctrl.addGroupExpense);
router.get('/:id/expenses', ctrl.listGroupExpenses);
router.get('/:id/balances', ctrl.getBalances);

module.exports = router;
