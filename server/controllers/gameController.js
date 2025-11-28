const GameHistory = require('../models/GameHistory');
const User = require('../models/User');

exports.saveGameHistory = async (req, res) => {
  try {
    const gameHistory = new GameHistory(req.body);
    await gameHistory.save();

    // Update user statistics
    for (const player of req.body.players) {
      if (player.userId) {
        const playerScore = player.score || 0;
        const currentLevel = req.body.level;
        
        const updateData = {
          $inc: {
            'statistics.totalGames': 1,
            'statistics.totalWins': player.isWinner ? 1 : 0,
            'statistics.totalLosses': !player.isWinner ? 1 : 0,
            'statistics.totalQuizzesAnswered': player.quizzesAnswered,
            'statistics.totalQuizzesCorrect': player.quizzesCorrect,
            'statistics.totalPlayTime': player.playTime,
            'statistics.totalScore': playerScore // Accumulate total score
          }
        };
        
        // Update highest score and unlock next level
        const maxUpdate = {};
        
        // Update highest score if current score is higher
        if (playerScore > 0) {
          maxUpdate['statistics.highestScore'] = playerScore;
        }
        
        // Only unlock next level if player wins
        if (player.isWinner) {
          // Unlock next level - player can access level after current level
          const nextLevel = currentLevel + 1;
          maxUpdate['statistics.highestLevel'] = nextLevel;
          console.log(`✅ Unlock level: ${nextLevel} (player won level ${currentLevel})`);
        }
        
        if (Object.keys(maxUpdate).length > 0) {
          updateData.$max = maxUpdate;
        }
        
        console.log(`📊 Updating player ${player.userId}:`, JSON.stringify(updateData, null, 2));
        const result = await User.findByIdAndUpdate(player.userId, updateData, { new: true });
        console.log(`✅ Updated stats:`, result.statistics);
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
    const { limit = 10, sortBy = 'score' } = req.query;

    let sortField = 'statistics.totalScore';
    if (sortBy === 'wins') sortField = 'statistics.totalWins';
    if (sortBy === 'games') sortField = 'statistics.totalGames';
    if (sortBy === 'quizzes') sortField = 'statistics.totalQuizzesCorrect';
    if (sortBy === 'highestScore') sortField = 'statistics.highestScore';

    const leaderboard = await User.find({ role: 'player', isActive: true })
      .select('username fullName avatar statistics')
      .sort({ [sortField]: -1 })
      .limit(parseInt(limit));

    res.json({
      success: true,
      data: leaderboard,
      sortBy: sortBy
    });
  } catch (error) {
    console.error('Get leaderboard error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Terjadi kesalahan saat mengambil leaderboard' 
    });
  }
};

exports.getDashboardStats = async (req, res) => {
  try {
    const userId = req.userId;

    // Get user profile with statistics
    const user = await User.findById(userId).select('username fullName avatar statistics');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User tidak ditemukan'
      });
    }

    // Get recent games
    const recentGames = await GameHistory.find({
      'players.userId': userId
    })
      .sort({ createdAt: -1 })
      .limit(5)
      .select('gameMode level duration createdAt players');

    // Get user rank in leaderboard
    const usersAbove = await User.countDocuments({
      role: 'player',
      isActive: true,
      'statistics.totalWins': { $gt: user.statistics.totalWins }
    });
    const userRank = usersAbove + 1;

    // Calculate win rate
    const winRate = user.statistics.totalGames > 0
      ? ((user.statistics.totalWins / user.statistics.totalGames) * 100).toFixed(1)
      : 0;

    // Calculate quiz accuracy
    const quizAccuracy = user.statistics.totalQuizzesAnswered > 0
      ? ((user.statistics.totalQuizzesCorrect / user.statistics.totalQuizzesAnswered) * 100).toFixed(1)
      : 0;

    res.json({
      success: true,
      data: {
        user: {
          username: user.username,
          fullName: user.fullName,
          avatar: user.avatar
        },
        statistics: {
          ...user.statistics.toObject(),
          winRate: parseFloat(winRate),
          quizAccuracy: parseFloat(quizAccuracy),
          rank: userRank
        },
        recentGames: recentGames.map(game => ({
          gameMode: game.gameMode,
          level: game.level,
          duration: game.duration,
          createdAt: game.createdAt,
          isWinner: game.players.find(p => p.userId && p.userId.toString() === userId)?.isWinner || false
        }))
      }
    });
  } catch (error) {
    console.error('Get dashboard stats error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Terjadi kesalahan saat mengambil dashboard statistics' 
    });
  }
};

exports.getGameAnalytics = async (req, res) => {
  try {
    const userId = req.userId;

    // Games by level
    const gamesByLevel = await GameHistory.aggregate([
      {
        $match: {
          'players.userId': userId
        }
      },
      {
        $group: {
          _id: '$level',
          totalGames: { $sum: 1 },
          wins: {
            $sum: {
              $cond: [
                {
                  $anyElementTrue: {
                    $map: {
                      input: '$players',
                      as: 'player',
                      in: {
                        $and: [
                          { $eq: ['$$player.userId', userId] },
                          { $eq: ['$$player.isWinner', true] }
                        ]
                      }
                    }
                  }
                },
                1,
                0
              ]
            }
          }
        }
      },
      {
        $sort: { _id: 1 }
      }
    ]);

    // Games by mode
    const gamesByMode = await GameHistory.aggregate([
      {
        $match: {
          'players.userId': userId
        }
      },
      {
        $group: {
          _id: '$gameMode',
          count: { $sum: 1 }
        }
      }
    ]);

    // Performance over time (last 7 days)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const performanceOverTime = await GameHistory.aggregate([
      {
        $match: {
          'players.userId': userId,
          createdAt: { $gte: sevenDaysAgo }
        }
      },
      {
        $group: {
          _id: {
            $dateToString: { format: '%Y-%m-%d', date: '$createdAt' }
          },
          games: { $sum: 1 },
          wins: {
            $sum: {
              $cond: [
                {
                  $anyElementTrue: {
                    $map: {
                      input: '$players',
                      as: 'player',
                      in: {
                        $and: [
                          { $eq: ['$$player.userId', userId] },
                          { $eq: ['$$player.isWinner', true] }
                        ]
                      }
                    }
                  }
                },
                1,
                0
              ]
            }
          }
        }
      },
      {
        $sort: { _id: 1 }
      }
    ]);

    res.json({
      success: true,
      data: {
        gamesByLevel,
        gamesByMode,
        performanceOverTime
      }
    });
  } catch (error) {
    console.error('Get game analytics error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Terjadi kesalahan saat mengambil game analytics' 
    });
  }
};
