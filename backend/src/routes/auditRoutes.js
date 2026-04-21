const router = require('express').Router();
const { getAuditLogs } = require('../controllers/auditController');
const { authenticate, authorize } = require('../middleware/authMiddleware');

router.get('/', authenticate, authorize('admin', 'finance'), getAuditLogs);

module.exports = router;
