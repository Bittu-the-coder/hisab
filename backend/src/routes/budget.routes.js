const router = require('express').Router();
const auth = require('../middleware/auth');
const ctrl = require('../controllers/budget.controller');

router.use(auth);
router.post('/', ctrl.create);
router.get('/', ctrl.get);
router.patch('/:id', ctrl.update);
router.delete('/:id', ctrl.delete);

module.exports = router;
