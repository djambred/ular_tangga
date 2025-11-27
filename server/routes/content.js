const express = require('express');
const router = express.Router();
const contentController = require('../controllers/contentController');
const { authenticate } = require('../middleware/auth');
const adminAuth = require('../middleware/adminAuth');

// Public routes
router.get('/:type', contentController.getContentByType);

// Admin routes
router.get('/', authenticate, adminAuth, contentController.getAllContents);
router.post('/', authenticate, adminAuth, contentController.createContent);
router.post('/bulk', authenticate, adminAuth, contentController.bulkCreateContents);
router.put('/:id', authenticate, adminAuth, contentController.updateContent);
router.delete('/:id', authenticate, adminAuth, contentController.deleteContent);

module.exports = router;
