const router = require('express').Router();
const { getDashboard } = require('../controllers/dashboardController');
const { authenticate } = require('../middleware/authMiddleware');

router.get('/', authenticate, getDashboard);

module.exports = router;
