const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  uid: { type: String, required: true, unique: true }, // Firebase UID
  name: { type: String, default: "" },
  email: { type: String, required: true },
  profilePhotoUrl: { type: String, default: "" }, // URL of profile photo
  preferredLanguage: { type: String, default: "en" },
});

module.exports = mongoose.model("User", UserSchema);
