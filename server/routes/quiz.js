const express = require('express');
const router = express.Router();
const quizController = require('../controllers/quizController');
const { authenticate, isAdmin } = require('../middleware/auth');

router.get('/', quizController.getAllQuizzes);
router.get('/statistics', authenticate, isAdmin, quizController.getQuizStatistics);
router.get('/:id', quizController.getQuizById);
router.post('/', authenticate, isAdmin, quizController.createQuiz);
router.put('/:id', authenticate, isAdmin, quizController.updateQuiz);
router.delete('/:id', authenticate, isAdmin, quizController.deleteQuiz);

module.exports = router;
