const Content = require('../models/Content');

// Get all content by type
exports.getContentByType = async (req, res) => {
  try {
    const { type } = req.params;
    
    if (!['snake_message', 'ladder_message', 'fact'].includes(type)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid content type'
      });
    }
    
    const contents = await Content.find({ type, isActive: true })
      .select('message')
      .sort({ createdAt: -1 });
    
    res.json({
      success: true,
      data: contents.map(c => c.message)
    });
  } catch (error) {
    console.error('Error fetching content:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch content'
    });
  }
};

// Get all contents (for admin)
exports.getAllContents = async (req, res) => {
  try {
    const { type, isActive } = req.query;
    
    const filter = {};
    if (type) filter.type = type;
    if (isActive !== undefined) filter.isActive = isActive === 'true';
    
    const contents = await Content.find(filter)
      .populate('createdBy', 'username')
      .populate('updatedBy', 'username')
      .sort({ type: 1, createdAt: -1 });
    
    res.json({
      success: true,
      data: contents
    });
  } catch (error) {
    console.error('Error fetching contents:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch contents'
    });
  }
};

// Create new content
exports.createContent = async (req, res) => {
  try {
    const { type, message } = req.body;
    
    if (!type || !message) {
      return res.status(400).json({
        success: false,
        message: 'Type and message are required'
      });
    }
    
    if (!['snake_message', 'ladder_message', 'fact'].includes(type)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid content type'
      });
    }
    
    const content = new Content({
      type,
      message,
      createdBy: req.user.id
    });
    
    await content.save();
    
    res.status(201).json({
      success: true,
      message: 'Content created successfully',
      data: content
    });
  } catch (error) {
    console.error('Error creating content:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create content'
    });
  }
};

// Update content
exports.updateContent = async (req, res) => {
  try {
    const { id } = req.params;
    const { message, isActive } = req.body;
    
    const updateData = { updatedBy: req.user.id };
    if (message !== undefined) updateData.message = message;
    if (isActive !== undefined) updateData.isActive = isActive;
    
    const content = await Content.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    );
    
    if (!content) {
      return res.status(404).json({
        success: false,
        message: 'Content not found'
      });
    }
    
    res.json({
      success: true,
      message: 'Content updated successfully',
      data: content
    });
  } catch (error) {
    console.error('Error updating content:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update content'
    });
  }
};

// Delete content
exports.deleteContent = async (req, res) => {
  try {
    const { id } = req.params;
    
    const content = await Content.findByIdAndDelete(id);
    
    if (!content) {
      return res.status(404).json({
        success: false,
        message: 'Content not found'
      });
    }
    
    res.json({
      success: true,
      message: 'Content deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting content:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete content'
    });
  }
};

// Bulk create contents (for initial seed)
exports.bulkCreateContents = async (req, res) => {
  try {
    const { contents } = req.body;
    
    if (!Array.isArray(contents) || contents.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Contents array is required'
      });
    }
    
    const contentDocs = contents.map(c => ({
      ...c,
      createdBy: req.user.id
    }));
    
    const result = await Content.insertMany(contentDocs);
    
    res.status(201).json({
      success: true,
      message: `${result.length} contents created successfully`,
      data: result
    });
  } catch (error) {
    console.error('Error bulk creating contents:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to bulk create contents'
    });
  }
};
