const router = require('express').Router();
const controller = require('../controllers/clientController');
const { authenticate, authorize } = require('../middleware/authMiddleware');

router.use(authenticate);
router.get('/', controller.getClients);
router.get('/:id', controller.getClientById);
router.post('/', authorize('admin', 'finance'), controller.createClient);
router.put('/:id', authorize('admin', 'finance'), controller.updateClient);
router.delete('/:id', authorize('admin'), controller.deleteClient);

module.exports = router;
