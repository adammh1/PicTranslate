const express = require("express");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");
const multer = require("multer");
const cors = require("cors");
const path = require("path");
const admin = require("firebase-admin");
const fs = require("fs").promises; 
const { spawn } = require("child_process");

const serviceAccount = require("./pictranslate-firebase-adminsdk-.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const app = express();
app.use(bodyParser.json());
app.use(cors());

mongoose.connect("mongodb://localhost:27028/flutter_mongo", {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

const db = mongoose.connection;
db.on("error", console.error.bind(console, "Connection error:"));
db.once("open", () => console.log("Connected to MongoDB"));

const userSchema = new mongoose.Schema({
  uid: { type: String, required: true, unique: true },
  name: { type: String },
  email: { type: String },
  preferredLanguage: { type: String },
  profilePhotoUrl: { type: String },
});

const User = mongoose.model("User", userSchema);

const upload = multer({ dest: "uploads/" });

async function verifyToken(req, res, next) {
  const token = req.headers["authorization"]?.split("Bearer ")[1];
  if (!token) return res.status(401).send("Token required");

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.uid = decodedToken.uid;
    next();
  } catch (error) {
    res.status(401).send("Unauthorized");
  }
}


app.get("/api/users/:uid", verifyToken, async (req, res) => {
  try {
    if (req.uid !== req.params.uid) return res.status(403).send("Forbidden");

    const user = await User.findOne({ uid: req.params.uid });
    if (!user) return res.status(404).send("User not found");
    res.json(user);
  } catch (error) {
    res.status(500).send("Error retrieving user: " + error.message);
  }
});

app.put("/api/users/:uid", verifyToken, async (req, res) => {
  try {
    if (req.uid !== req.params.uid) return res.status(403).send("Forbidden");

    const { name, preferredLanguage, profilePhotoUrl } = req.body;
    const updatedUser = await User.findOneAndUpdate(
      { uid: req.params.uid },
      { name, preferredLanguage, profilePhotoUrl },
      { new: true, upsert: true }
    );
    res.json(updatedUser);
  } catch (error) {
    res.status(500).send("Error updating user: " + error.message);
  }
});

app.post("/api/translate", upload.single("image"), async (req, res) => {
  try {
    const { sourceLanguage, targetLanguage } = req.body;
    const file = req.file;

    if (!file || !sourceLanguage || !targetLanguage) {
      return res.status(400).json({
        error: "Missing required parameters (image, sourceLanguage, targetLanguage)",
      });
    }

    const pythonProcess = spawn("python", [
      "./translate.py",
      file.path,
      sourceLanguage,
      targetLanguage,
    ]);

    let result = "";
    let error = "";

pythonProcess.stdout.on("data", (data) => {
  result += data.toString();
});

pythonProcess.stderr.on("data", (data) => {
  console.error(data.toString());
});


    pythonProcess.on("close", async (code) => {
      await fs.unlink(file.path).catch(console.error);

      if (code === 0 && result.trim()) {
        res.json({ translatedText: result.trim() });
      } else {
        res.status(500).json({
          error: error || "Error during translation process",
        });
      }
    });
  } catch (error) {
    console.error(error);
    if (req.file) {
      await fs.unlink(req.file.path).catch(console.error);
    }
    res.status(500).json({ error: "Failed to process the image" });
  }
});

app.use("/uploads", express.static(path.join(__dirname, "uploads")));

const PORT = 3000;
app.listen(PORT, () => console.log(`Server running on http://localhost:${PORT}`));
