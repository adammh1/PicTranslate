const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  uid: { type: String, required: true, unique: true }, 
  name: { type: String, default: "" },
  email: { type: String, required: true },
  profilePhotoUrl: { type: String, default: "" }, 
  preferredLanguage: { type: String, default: "en" },
});

module.exports = mongoose.model("User", UserSchema);
