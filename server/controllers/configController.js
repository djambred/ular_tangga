const AppConfig = require('../models/AppConfig');

// Get public app configurations (for client app)
exports.getPublicConfigs = async (req, res) => {
  try {
    const configs = await AppConfig.find({ isPublic: true })
      .select('key value description category')
      .sort({ category: 1, key: 1 });
    
    // Convert to key-value object for easier use in client
    const configObj = {};
    configs.forEach(config => {
      configObj[config.key] = config.value;
    });
    
    res.json({
      success: true,
      data: configObj,
      raw: configs // Also send raw data with descriptions
    });
  } catch (error) {
    console.error('Error fetching public configs:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch configurations'
    });
  }
};

// Get all configurations (admin only)
exports.getAllConfigs = async (req, res) => {
  try {
    const { category, isPublic } = req.query;
    
    const filter = {};
    if (category) filter.category = category;
    if (isPublic !== undefined) filter.isPublic = isPublic === 'true';
    
    const configs = await AppConfig.find(filter)
      .populate('updatedBy', 'username')
      .sort({ category: 1, key: 1 });
    
    res.json({
      success: true,
      data: configs
    });
  } catch (error) {
    console.error('Error fetching configs:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch configurations'
    });
  }
};

// Get single config by key
exports.getConfigByKey = async (req, res) => {
  try {
    const { key } = req.params;
    
    const config = await AppConfig.findOne({ key });
    
    if (!config) {
      return res.status(404).json({
        success: false,
        message: 'Configuration not found'
      });
    }
    
    // Check if user has permission to view private config
    if (!config.isPublic && (!req.user || req.user.role !== 'admin')) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }
    
    res.json({
      success: true,
      data: config
    });
  } catch (error) {
    console.error('Error fetching config:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch configuration'
    });
  }
};

// Create or update config
exports.upsertConfig = async (req, res) => {
  try {
    const { key, value, description, category, isPublic } = req.body;
    
    if (!key || value === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Key and value are required'
      });
    }
    
    const updateData = {
      value,
      updatedBy: req.user.id
    };
    
    if (description !== undefined) updateData.description = description;
    if (category !== undefined) updateData.category = category;
    if (isPublic !== undefined) updateData.isPublic = isPublic;
    
    const config = await AppConfig.findOneAndUpdate(
      { key },
      updateData,
      { 
        new: true, 
        upsert: true,
        runValidators: true,
        setDefaultsOnInsert: true
      }
    );
    
    res.json({
      success: true,
      message: 'Configuration saved successfully',
      data: config
    });
  } catch (error) {
    console.error('Error saving config:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to save configuration'
    });
  }
};

// Delete config
exports.deleteConfig = async (req, res) => {
  try {
    const { key } = req.params;
    
    const config = await AppConfig.findOneAndDelete({ key });
    
    if (!config) {
      return res.status(404).json({
        success: false,
        message: 'Configuration not found'
      });
    }
    
    res.json({
      success: true,
      message: 'Configuration deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting config:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete configuration'
    });
  }
};

// Bulk upsert configs (for initialization)
exports.bulkUpsertConfigs = async (req, res) => {
  try {
    const { configs } = req.body;
    
    if (!Array.isArray(configs) || configs.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Configs array is required'
      });
    }
    
    const results = [];
    
    for (const configData of configs) {
      const { key, value, description, category, isPublic } = configData;
      
      if (!key || value === undefined) continue;
      
      const config = await AppConfig.findOneAndUpdate(
        { key },
        {
          value,
          description,
          category,
          isPublic,
          updatedBy: req.user.id
        },
        { 
          new: true, 
          upsert: true,
          runValidators: true,
          setDefaultsOnInsert: true
        }
      );
      
      results.push(config);
    }
    
    res.json({
      success: true,
      message: `${results.length} configurations saved successfully`,
      data: results
    });
  } catch (error) {
    console.error('Error bulk saving configs:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to bulk save configurations'
    });
  }
};
