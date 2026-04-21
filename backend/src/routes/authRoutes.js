const router = require('express').Router();
const { login, logout } = require('../controllers/authController');
const { authenticate } = require('../middleware/authMiddleware');

router.post('/login', login);
router.post('/logout', authenticate, logout);

module.exports = router;
