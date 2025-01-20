const express = require("express");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");
const multer = require("multer");
const cors = require("cors");
const path = require("path");
const admin = require("firebase-admin");
const fs = require("fs").promises;
const { spawn } = require("child_process");
const  fileType  = require('file-type');
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
const translationSchema = new mongoose.Schema({
  uid: { type: String, required: true },
  originalText: { type: String, required: true },
  translatedText: { type: String, required: true },
  date: { type: Date, default: Date.now },
});

const Translation = mongoose.model("Translation", translationSchema);

const userSchema = new mongoose.Schema({
  uid: { type: String, required: true, unique: true },
  name: { type: String },
  email: { type: String },
  preferredLanguage: { type: String },
  profilePhotoUrl: { type: String }, 
});

const User = mongoose.model("User", userSchema);

const upload = multer({ dest: "uploads/" });

const verifyToken = async (req, res, next) => {
  const token = req.headers.authorization?.split("Bearer ")[1];
  if (!token) {
    return res.status(401).json({ error: "Authorization token missing" });
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    console.log("Decoded Token:", decodedToken); 
    req.uid = decodedToken.uid; 
    next();
  } catch (error) {
    console.error("Token verification failed:", error);
    res.status(401).json({ error: "Invalid token" });
  }
};

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
    console.error("Error updating user:", error);
    res.status(500).send("Error updating user: " + error.message);
  }
});

app.post("/api/translations", verifyToken, async (req, res) => {
  try {
    const { originalText, translatedText } = req.body;

    console.log("Request Body:", req.body);
    console.log("UID:", req.uid);

    if (!originalText || !translatedText) {
      return res.status(400).json({ error: "Missing required fields: originalText or translatedText" });
    }

    if (!req.uid) {
      return res.status(400).json({ error: "UID is missing, check token validation middleware" });
    }

    const newTranslation = new Translation({
      uid: req.uid,
      originalText,
      translatedText,
    });

    console.log("Translation Data to Save:", newTranslation);

    await newTranslation.save();

    res.status(201).json(newTranslation);
  } catch (error) {
    console.error("Error saving translation:", error);
    res.status(500).json({ error: "Failed to save translation" });
  }
});

app.get("/api/translations", verifyToken, async (req, res) => {
  try {
    const translations = await Translation.find({ uid: req.uid }).sort({ date: -1 });
    res.json(translations);
  } catch (error) {
    console.error("Error fetching translations:", error);
    res.status(500).json({ error: "Failed to fetch translations" });
  }
});


app.post("/api/users/:uid", verifyToken, upload.single("profilePhoto"), async (req, res) => {
  try {
    console.log("File upload request received");

    if (req.uid !== req.params.uid) {
      console.log("UID mismatch");
      return res.status(403).send("Forbidden");
    }

    const file = req.file;
    if (!file) {
      console.log("No file uploaded");
      return res.status(400).json({ error: "No file uploaded" });
    }

    console.log("File uploaded:", file);

    await fs.access(file.path); 

    const buffer = await fs.readFile(file.path);
    
    const type = await fileType.fromBuffer(buffer); 
    if (!type || !["image/jpeg", "image/png", "image/gif"].includes(type.mime)) {
      console.log("Unsupported file type:", type ? type.mime : "unknown");
      await fs.unlink(file.path); 
      return res.status(400).json({ error: "Unsupported file type" });
    }

    console.log("Valid image type detected:", type.mime);

    const base64Image = `data:${type.mime};base64,${buffer.toString("base64")}`;
    console.log("Base64 Image:", base64Image);

    const updatedUser = await User.findOneAndUpdate(
      { uid: req.params.uid },
      { profilePhotoUrl: base64Image }, 
      { new: true, upsert: true } 
    );

    if (!updatedUser) {
      console.log("Failed to update user in database");
      await fs.unlink(file.path); 
      return res.status(500).json({ error: "Failed to update user in database" });
    }

    console.log("User updated successfully:", updatedUser);

    await fs.unlink(file.path);
    console.log("Temporary file deleted");

    res.json({ message: "Profile photo uploaded and updated successfully", user: updatedUser });
  } catch (error) {
    console.error("Error processing the uploaded file:", error);
    if (req.file) {
      await fs.unlink(req.file.path).catch(console.error);
    }
    res.status(500).json({ error: "Failed to upload profile photo" });
  }
});

app.post("/api/translate", upload.single("image"), verifyToken, async (req, res) => {
  try {
    const { sourceLanguage, targetLanguage } = req.body;
    const file = req.file;

    console.log("Request Body:", req.body);
    console.log("UID:", req.uid); 
    console.log("File Info:", file);

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
      error += data.toString();
      console.error(data.toString());
    });

    pythonProcess.on("close", async (code) => {
      await fs.unlink(file.path).catch(console.error);

      if (code === 0 && result.trim()) {
        try {
          const parsedResult = JSON.parse(result.trim());
          const { originalText, translatedText } = parsedResult;

          if (!req.uid) {
            return res.status(400).json({
              error: "UID is missing, check token validation middleware",
            });
          }

          const newTranslation = new Translation({
            uid: req.uid, 
            originalText,
            translatedText,
          });

          console.log("Saving Translation:", newTranslation);

          await newTranslation.save();

          res.json(parsedResult);
        } catch (saveError) {
          console.error("Error saving translation:", saveError);
          res.status(500).json({
            error: "Failed to save translation",
          });
        }
      } else {
        res.status(500).json({
          error: error || "Error during translation process",
        });
      }
    });
  } catch (error) {
    console.error("Error processing image:", error);
    if (req.file) {
      await fs.unlink(req.file.path).catch(console.error);
    }
    res.status(500).json({ error: "Failed to process the image" });
  }
});


app.use("/uploads", express.static(path.join(__dirname, "uploads")));

const PORT = 3000;
app.listen(PORT, () => console.log(`Server running on http://localhost:${PORT}`));
