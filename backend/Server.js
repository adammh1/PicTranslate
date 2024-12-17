const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const multer = require('multer');
const cors = require('cors');
const path = require('path');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./pictranslate-d4da7-firebase-adminsdk-54fhy-cc89068b3a.json'); // Update path
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// App setup
const app = express();
app.use(bodyParser.json());
app.use(cors());

// MongoDB connection
mongoose.connect('mongodb://localhost:27028/flutter_mongo', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

const db = mongoose.connection;
db.on('error', console.error.bind(console, 'Connection error:'));
db.once('open', () => console.log('Connected to MongoDB'));

// Define User Schema
const userSchema = new mongoose.Schema({
  uid: { type: String, required: true, unique: true },
  name: { type: String },
  email: { type: String },
  preferredLanguage: { type: String },
  profilePhotoUrl: { type: String },
});

const User = mongoose.model('User', userSchema);

// Multer setup for file uploads
const upload = multer({ dest: 'uploads/' });

// Middleware to verify Firebase token
async function verifyToken(req, res, next) {
  const token = req.headers['authorization']?.split('Bearer ')[1];
  if (!token) return res.status(401).send('Token required');

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.uid = decodedToken.uid; // Attach UID to request
    next();
  } catch (error) {
    res.status(401).send('Unauthorized');
  }
}

// API Endpoints

// Get user data
app.get('/api/users/:uid', verifyToken, async (req, res) => {
  try {
    if (req.uid !== req.params.uid) return res.status(403).send('Forbidden');

    const user = await User.findOne({ uid: req.params.uid });
    if (!user) return res.status(404).send('User not found');
    res.json(user);
  } catch (error) {
    res.status(500).send('Error retrieving user: ' + error.message);
  }
});

// Update user data
app.put('/api/users/:uid', verifyToken, async (req, res) => {
  try {
    if (req.uid !== req.params.uid) return res.status(403).send('Forbidden');

    const { name, preferredLanguage, profilePhotoUrl } = req.body;
    const updatedUser = await User.findOneAndUpdate(
      { uid: req.params.uid },
      { name, preferredLanguage, profilePhotoUrl },
      { new: true, upsert: true }
    );
    res.json(updatedUser);
  } catch (error) {
    res.status(500).send('Error updating user: ' + error.message);
  }
});

// Upload profile photo
app.post('/api/users/:uid/upload', verifyToken, upload.single('profilePhoto'), async (req, res) => {
  try {
    if (req.uid !== req.params.uid) return res.status(403).send('Forbidden');

    const photoUrl = `http://localhost:3000/uploads/${req.file.filename}`;

    await User.findOneAndUpdate(
      { uid: req.params.uid },
      { profilePhotoUrl: photoUrl },
      { new: true, upsert: true }
    );

    res.json({ profilePhotoUrl: photoUrl });
  } catch (error) {
    res.status(500).send('Error uploading photo: ' + error.message);
  }
});

// Request email verification
app.post('/api/users/:uid/email/verify', verifyToken, async (req, res) => {
  try {
    if (req.uid !== req.params.uid) return res.status(403).send('Forbidden');

    const user = await admin.auth().getUser(req.uid);
    await admin.auth().generateEmailVerificationLink(user.email);

    res.json({ message: 'Verification email sent successfully' });
  } catch (error) {
    res.status(500).send('Error sending verification email: ' + error.message);
  }
});

// Update email
app.put('/api/users/:uid/email', verifyToken, async (req, res) => {
  try {
    if (req.uid !== req.params.uid) return res.status(403).send('Forbidden');

    const { newEmail } = req.body;
    if (!newEmail) return res.status(400).send('New email is required');

    const userRecord = await admin.auth().updateUser(req.uid, { email: newEmail });

    // Update in MongoDB
    await User.findOneAndUpdate(
      { uid: req.params.uid },
      { email: userRecord.email },
      { new: true }
    );

    res.json({ message: 'Email updated successfully' });
  } catch (error) {
    res.status(500).send('Error updating email: ' + error.message);
  }
});

// Serve uploaded files
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Start server
const PORT = 3000;
app.listen(PORT, () => console.log(`Server running on http://localhost:${PORT}`));
