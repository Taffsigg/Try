const router = require('express').Router();
const controller = require('../controllers/transactionController');
const { authenticate, authorize } = require('../middleware/authMiddleware');

router.use(authenticate);
router.get('/', controller.getTransactions);
router.post('/', authorize('admin', 'finance', 'operations'), controller.createTransaction);
router.put('/:id', authorize('admin', 'finance'), controller.updateTransaction);

module.exports = router;
