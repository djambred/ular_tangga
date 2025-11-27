const Quiz = require('../models/Quiz');

exports.getAllQuizzes = async (req, res) => {
  try {
    const { category, difficulty, isActive } = req.query;
    const filter = {};

    if (category) filter.category = category;
    if (difficulty) filter.difficulty = difficulty;
    if (isActive !== undefined) filter.isActive = isActive === 'true';

    const quizzes = await Quiz.find(filter).sort({ createdAt: -1 });

    res.json({
      success: true,
      data: quizzes,
      total: quizzes.length
    });
  } catch (error) {
    console.error('Get quizzes error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Terjadi kesalahan saat mengambil data quiz' 
    });
  }
};

exports.getQuizById = async (req, res) => {
  try {
    const quiz = await Quiz.findById(req.params.id);

    if (!quiz) {
      return res.status(404).json({ 
        success: false, 
        message: 'Quiz tidak ditemukan' 
      });
    }

    res.json({
      success: true,
      data: quiz
    });
  } catch (error) {
    console.error('Get quiz error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Terjadi kesalahan saat mengambil data quiz' 
    });
  }
};

exports.createQuiz = async (req, res) => {
  try {
    const { question, options, correctAnswer, explanation, category, difficulty } = req.body;

    // Validate input
    if (!question || !options || correctAnswer === undefined || !explanation) {
      return res.status(400).json({ 
        success: false, 
        message: 'Semua field wajib diisi' 
      });
    }

    if (options.length !== 4) {
      return res.status(400).json({ 
        success: false, 
        message: 'Quiz harus memiliki 4 pilihan jawaban' 
      });
    }

    const quiz = new Quiz({
      question,
      options,
      correctAnswer,
      explanation,
      category,
      difficulty
    });

    await quiz.save();

    res.status(201).json({
      success: true,
      message: 'Quiz berhasil dibuat',
      data: quiz
    });
  } catch (error) {
    console.error('Create quiz error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Terjadi kesalahan saat membuat quiz' 
    });
  }
};

exports.updateQuiz = async (req, res) => {
  try {
    const { question, options, correctAnswer, explanation, category, difficulty, isActive } = req.body;

    const quiz = await Quiz.findByIdAndUpdate(
      req.params.id,
      { question, options, correctAnswer, explanation, category, difficulty, isActive },
      { new: true, runValidators: true }
    );

    if (!quiz) {
      return res.status(404).json({ 
        success: false, 
        message: 'Quiz tidak ditemukan' 
      });
    }

    res.json({
      success: true,
      message: 'Quiz berhasil diupdate',
      data: quiz
    });
  } catch (error) {
    console.error('Update quiz error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Terjadi kesalahan saat update quiz' 
    });
  }
};

exports.deleteQuiz = async (req, res) => {
  try {
    const quiz = await Quiz.findByIdAndDelete(req.params.id);

    if (!quiz) {
      return res.status(404).json({ 
        success: false, 
        message: 'Quiz tidak ditemukan' 
      });
    }

    res.json({
      success: true,
      message: 'Quiz berhasil dihapus'
    });
  } catch (error) {
    console.error('Delete quiz error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Terjadi kesalahan saat menghapus quiz' 
    });
  }
};

exports.getQuizStatistics = async (req, res) => {
  try {
    const totalQuizzes = await Quiz.countDocuments();
    const activeQuizzes = await Quiz.countDocuments({ isActive: true });
    
    const categoryStats = await Quiz.aggregate([
      { $group: { _id: '$category', count: { $sum: 1 } } }
    ]);

    const difficultyStats = await Quiz.aggregate([
      { $group: { _id: '$difficulty', count: { $sum: 1 } } }
    ]);

    res.json({
      success: true,
      data: {
        total: totalQuizzes,
        active: activeQuizzes,
        inactive: totalQuizzes - activeQuizzes,
        byCategory: categoryStats,
        byDifficulty: difficultyStats
      }
    });
  } catch (error) {
    console.error('Get quiz statistics error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Terjadi kesalahan saat mengambil statistik quiz' 
    });
  }
};
