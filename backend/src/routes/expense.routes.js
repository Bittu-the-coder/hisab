const router = require('express').Router();
const auth = require('../middleware/auth');
const ctrl = require('../controllers/expense.controller');

router.use(auth);
router.post('/', ctrl.create);
router.get('/', ctrl.list);
router.get('/:id', ctrl.get);
router.patch('/:id', ctrl.update);
router.delete('/:id', ctrl.remove);

module.exports = router;
