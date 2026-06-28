const router = require('express').Router();
const auth = require('../middleware/auth');
const ctrl = require('../controllers/user.controller');

router.use(auth);
router.get('/me', ctrl.getMe);
router.patch('/me', ctrl.updateMe);
router.get('/balance', ctrl.getBalance);
router.put('/balance', ctrl.updateBalance);

module.exports = router;
