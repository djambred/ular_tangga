const express = require('express');
const router = express.Router();
const configController = require('../controllers/configController');
const { authenticate } = require('../middleware/auth');
const adminAuth = require('../middleware/adminAuth');

// Public routes
router.get('/public', configController.getPublicConfigs);

// Admin routes
router.get('/', authenticate, adminAuth, configController.getAllConfigs);
router.get('/:key', authenticate, configController.getConfigByKey);
router.post('/', authenticate, adminAuth, configController.upsertConfig);
router.post('/bulk', authenticate, adminAuth, configController.bulkUpsertConfigs);
router.delete('/:key', authenticate, adminAuth, configController.deleteConfig);

module.exports = router;
