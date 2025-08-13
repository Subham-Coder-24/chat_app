const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const Message = require('./models/Message');
const User = require('./models/User');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);

// MongoDB Connection
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/chatapp', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('MongoDB connected'))
.catch(err => console.log('MongoDB connection error:', err));

// Socket.IO Authentication Middleware
io.use(async (socket, next) => {
  try {
    const token = socket.handshake.auth.token;
    if (!token) {
      return next(new Error('Authentication error'));
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret');
    const user = await User.findById(decoded.userId).select('-password');
    
    if (!user) {
      return next(new Error('User not found'));
    }

    socket.userId = user._id.toString();
    socket.userEmail = user.email;
    next();
  } catch (err) {
    next(new Error('Authentication error'));
  }
});

// Socket.IO Connection Handler
io.on('connection', (socket) => {
  console.log(`User connected: ${socket.userEmail} (${socket.userId})`);

  // Join user to their own room
  socket.join(socket.userId);

  // Handle sending messages
  socket.on('send_message', async (data) => {
    try {
      const { receiverId, content } = data;
      
      // Save message to database
      const message = new Message({
        senderId: socket.userId,
        receiverId,
        content,
        timestamp: new Date()
      });
      
      await message.save();
      
      // Send message to receiver
      socket.to(receiverId).emit('receive_message', {
        _id: message._id,
        senderId: {
          _id: socket.userId,
          email: socket.userEmail
        },
        receiverId,
        content: message.content,
        timestamp: message.timestamp
      });
      
      // Send confirmation to sender
      socket.emit('message_sent', {
        _id: message._id,
        senderId: {
          _id: socket.userId,
          email: socket.userEmail
        },
        receiverId,
        content: message.content,
        timestamp: message.timestamp
      });
      
    } catch (error) {
      console.error('Error sending message:', error);
      socket.emit('error', 'Failed to send message');
    }
  });

  // Handle getting chat history
  socket.on('get_chat_history', async (data) => {
    try {
      const { otherUserId } = data;
      const messages = await Message.find({
        $or: [
          { senderId: socket.userId, receiverId: otherUserId },
          { senderId: otherUserId, receiverId: socket.userId }
        ]
      })
      .populate('senderId', 'email')
      .populate('receiverId', 'email')
      .sort({ timestamp: 1 });
      
      socket.emit('chat_history', messages);
    } catch (error) {
      console.error('Error fetching chat history:', error);
      socket.emit('error', 'Failed to fetch chat history');
    }
  });

  socket.on('disconnect', () => {
    console.log(`User disconnected: ${socket.userEmail}`);
  });
});

// Get all users endpoint
app.get('/api/users', async (req, res) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret');
    const users = await User.find({ _id: { $ne: decoded.userId } }).select('email');
    res.json(users);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});
app.get('/', async (req, res) => {
  return res.status(200).json({ message: 'welcome' });
});
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});