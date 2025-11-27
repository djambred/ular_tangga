const express = require('express');
const router = express.Router();
const boardController = require('../controllers/boardController');
const { authenticate, isAdmin } = require('../middleware/auth');

router.get('/', boardController.getAllBoardConfigs);
router.get('/:level', boardController.getBoardConfigByLevel);
router.post('/', authenticate, isAdmin, boardController.createBoardConfig);
router.post('/generate', authenticate, isAdmin, boardController.generateBoardConfig);
router.put('/:level', authenticate, isAdmin, boardController.updateBoardConfig);
router.delete('/:level', authenticate, isAdmin, boardController.deleteBoardConfig);

module.exports = router;
