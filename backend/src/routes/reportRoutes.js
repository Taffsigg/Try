const router = require('express').Router();
const { exportTransactionsExcel } = require('../controllers/reportController');
const { authenticate, authorize } = require('../middleware/authMiddleware');

router.get('/export', authenticate, authorize('admin', 'finance'), exportTransactionsExcel);

module.exports = router;
