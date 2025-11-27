const express = require('express');
const router = express.Router();
const gameController = require('../controllers/gameController');
const { authenticate, isAdmin } = require('../middleware/auth');

router.post('/history', authenticate, gameController.saveGameHistory);
router.get('/history', authenticate, gameController.getUserGameHistory);
router.get('/history/all', authenticate, isAdmin, gameController.getAllGameHistory);
router.get('/statistics', authenticate, isAdmin, gameController.getGameStatistics);
router.get('/leaderboard', gameController.getLeaderboard);
router.get('/dashboard', authenticate, gameController.getDashboardStats);
router.get('/analytics', authenticate, gameController.getGameAnalytics);

module.exports = router;
