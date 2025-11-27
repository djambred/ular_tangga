const GameHistory = require('../models/GameHistory');
const User = require('../models/User');

exports.saveGameHistory = async (req, res) => {
  try {
    const gameHistory = new GameHistory(req.body);
    await gameHistory.save();

    // Update user statistics
    for (const player of req.body.players) {
      if (player.userId) {
        await User.findByIdAndUpdate(player.userId, {
          $inc: {
            'statistics.totalGames': 1,
            'statistics.totalWins': player.isWinner ? 1 : 0,
            'statistics.totalLosses': !player.isWinner ? 1 : 0,
            'statistics.totalQuizzesAnswered': player.quizzesAnswered,
            'statistics.totalQuizzesCorrect': player.quizzesCorrect,
            'statistics.totalPlayTime': player.playTime
          },
          $max: {
            'statistics.highestLevel': req.body.level
          }
        });
      }
    }

    res.status(201).json({
      success: true,
      message: 'Game history berhasil disimpan',
      data: gameHistory
    });
  } catch (error) {
    console.error('Save game history error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Terjadi kesalahan saat menyimpan game history' 
    });
  }
};

exports.getUserGameHistory = async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const skip = (page - 1) * limit;

    const history = await GameHistory.find({
      'players.userId': req.userId
    })
      .populate('quizzes.quizId', 'question category')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await GameHistory.countDocuments({
      'players.userId': req.userId
    });

    res.json({
      success: true,
      data: history,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get user game history error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Terjadi kesalahan saat mengambil game history' 
    });
  }
};

exports.getAllGameHistory = async (req, res) => {
  try {
    const { page = 1, limit = 20, gameMode, level } = req.query;
    const skip = (page - 1) * limit;
    const filter = {};

    if (gameMode) filter.gameMode = gameMode;
    if (level) filter.level = parseInt(level);

    const history = await GameHistory.find(filter)
      .populate('players.userId', 'username fullName')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await GameHistory.countDocuments(filter);

    res.json({
      success: true,
      data: history,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get all game history error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Terjadi kesalahan saat mengambil game history' 
    });
  }
};

exports.getGameStatistics = async (req, res) => {
  try {
    const totalGames = await GameHistory.countDocuments();
    const singlePlayerGames = await GameHistory.countDocuments({ gameMode: 'single' });
    const multiplayerGames = await GameHistory.countDocuments({ gameMode: 'multiplayer' });

    const avgDuration = await GameHistory.aggregate([
      { $group: { _id: null, avgDuration: { $avg: '$duration' } } }
    ]);

    const levelStats = await GameHistory.aggregate([
      { $group: { _id: '$level', count: { $sum: 1 } } },
      { $sort: { _id: 1 } }
    ]);

    const recentGames = await GameHistory.find()
      .populate('players.userId', 'username')
      .sort({ createdAt: -1 })
      .limit(10);

    res.json({
      success: true,
      data: {
        total: totalGames,
        singlePlayer: singlePlayerGames,
        multiplayer: multiplayerGames,
        averageDuration: avgDuration[0]?.avgDuration || 0,
        byLevel: levelStats,
        recentGames
      }
    });
  } catch (error) {
    console.error('Get game statistics error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Terjadi kesalahan saat mengambil statistik game' 
    });
  }
};

exports.getLeaderboard = async (req, res) => {
  try {
    const { limit = 10, sortBy = 'wins' } = req.query;

    let sortField = 'statistics.totalWins';
    if (sortBy === 'games') sortField = 'statistics.totalGames';
    if (sortBy === 'quizzes') sortField = 'statistics.totalQuizzesCorrect';

    const leaderboard = await User.find({ role: 'player', isActive: true })
      .select('username fullName avatar statistics')
      .sort({ [sortField]: -1 })
      .limit(parseInt(limit));

    res.json({
      success: true,
      data: leaderboard
    });
  } catch (error) {
    console.error('Get leaderboard error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Terjadi kesalahan saat mengambil leaderboard' 
    });
  }
};
