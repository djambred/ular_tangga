const BoardConfig = require('../models/BoardConfig');
const Quiz = require('../models/Quiz');

// Get all board configs
exports.getAllBoardConfigs = async (req, res) => {
  try {
    const configs = await BoardConfig.find()
      .populate('quizPositions.quizId', 'question category')
      .sort({ level: 1 });

    res.json({
      success: true,
      data: configs
    });
  } catch (error) {
    console.error('Get board configs error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Terjadi kesalahan saat mengambil konfigurasi board' 
    });
  }
};

// Get board config by level
exports.getBoardConfigByLevel = async (req, res) => {
  try {
    const config = await BoardConfig.findOne({ level: req.params.level })
      .populate('quizPositions.quizId');

    if (!config) {
      return res.status(404).json({ 
        success: false, 
        message: 'Konfigurasi board tidak ditemukan' 
      });
    }

    res.json({
      success: true,
      data: config
    });
  } catch (error) {
    console.error('Get board config error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Terjadi kesalahan saat mengambil konfigurasi board' 
    });
  }
};

// Create board config
exports.createBoardConfig = async (req, res) => {
  try {
    const { level, snakes, ladders, quizPositions, requiredQuizzes } = req.body;

    // Check if level already exists
    const existing = await BoardConfig.findOne({ level });
    if (existing) {
      return res.status(400).json({ 
        success: false, 
        message: 'Konfigurasi untuk level ini sudah ada' 
      });
    }

    const config = new BoardConfig({
      level,
      snakes,
      ladders,
      quizPositions,
      requiredQuizzes
    });

    await config.save();

    res.status(201).json({
      success: true,
      message: 'Konfigurasi board berhasil dibuat',
      data: config
    });
  } catch (error) {
    console.error('Create board config error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Terjadi kesalahan saat membuat konfigurasi board' 
    });
  }
};

// Update board config
exports.updateBoardConfig = async (req, res) => {
  try {
    const { snakes, ladders, quizPositions, requiredQuizzes, isActive } = req.body;

    const config = await BoardConfig.findOneAndUpdate(
      { level: req.params.level },
      { snakes, ladders, quizPositions, requiredQuizzes, isActive },
      { new: true, runValidators: true }
    );

    if (!config) {
      return res.status(404).json({ 
        success: false, 
        message: 'Konfigurasi board tidak ditemukan' 
      });
    }

    res.json({
      success: true,
      message: 'Konfigurasi board berhasil diupdate',
      data: config
    });
  } catch (error) {
    console.error('Update board config error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Terjadi kesalahan saat update konfigurasi board' 
    });
  }
};

// Delete board config
exports.deleteBoardConfig = async (req, res) => {
  try {
    const config = await BoardConfig.findOneAndDelete({ level: req.params.level });

    if (!config) {
      return res.status(404).json({ 
        success: false, 
        message: 'Konfigurasi board tidak ditemukan' 
      });
    }

    res.json({
      success: true,
      message: 'Konfigurasi board berhasil dihapus'
    });
  } catch (error) {
    console.error('Delete board config error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Terjadi kesalahan saat menghapus konfigurasi board' 
    });
  }
};

// Generate random board config
exports.generateBoardConfig = async (req, res) => {
  try {
    const { level } = req.body;

    // Get 10 random quizzes
    const quizzes = await Quiz.aggregate([
      { $match: { isActive: true } },
      { $sample: { size: 10 } }
    ]);

    if (quizzes.length < 10) {
      return res.status(400).json({ 
        success: false, 
        message: 'Tidak cukup quiz aktif. Minimal 10 quiz diperlukan.' 
      });
    }

    // Generate random snakes
    const snakes = [];
    const usedPositions = new Set();
    
    for (let i = 0; i < 10; i++) {
      let start, end;
      do {
        start = Math.floor(Math.random() * 60) + 21; // 21-80
        end = Math.floor(Math.random() * (start - 10)) + 5; // end < start
      } while (usedPositions.has(start) || usedPositions.has(end));
      
      snakes.push({ start, end });
      usedPositions.add(start);
      usedPositions.add(end);
    }

    // Generate random ladders
    const ladders = [];
    
    for (let i = 0; i < 10; i++) {
      let start, end;
      do {
        start = Math.floor(Math.random() * 70) + 1; // 1-70
        end = Math.min(start + Math.floor(Math.random() * 20) + 5, 95); // start + 5-25, max 95
      } while (usedPositions.has(start) || usedPositions.has(end));
      
      ladders.push({ start, end });
      usedPositions.add(start);
      usedPositions.add(end);
    }

    // Generate quiz positions
    const quizPositions = [];
    
    for (let i = 0; i < 10; i++) {
      let position;
      do {
        position = Math.floor(Math.random() * 71) + 10; // 10-80
      } while (usedPositions.has(position));
      
      quizPositions.push({
        position,
        quizId: quizzes[i]._id
      });
      usedPositions.add(position);
    }

    const config = {
      level,
      snakes,
      ladders,
      quizPositions,
      requiredQuizzes: level
    };

    res.json({
      success: true,
      data: config,
      message: 'Konfigurasi board berhasil di-generate'
    });
  } catch (error) {
    console.error('Generate board config error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Terjadi kesalahan saat generate konfigurasi board' 
    });
  }
};
