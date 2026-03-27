import connect2DB from "../lib/db.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import crypto from "crypto";
import dotenv from "dotenv";

dotenv.config();

// Token lifetimes
const ACCESS_TOKEN_EXPIRES = "15m"; // access token: 15 minutes
const REFRESH_TOKEN_EXPIRES_DAYS = 14; // refresh token: 14 days


// Helper to generate refresh token
const generateRefreshToken = () => crypto.randomBytes(64).toString("hex");

// Hash a token before storing in DB
const hashToken = (token) => crypto.createHash("sha256").update(token).digest("hex");


// REGISTER
export const RegisterUser = async (req, res) => {
  const { username, email, password, phone, shop_name } = req.body;
  
  // Get the Cloudinary URL if file was uploaded
  const profile_picture = req.file ? req.file.path : null;

  if (!username || !email || !password) {
    return res.status(400).json({ message: "All fields are required" });
  }

  try {
    // connect to db
    const db = await connect2DB();
    
    // check if email already exists
    const [existingUser] = await db.execute(
      "SELECT * FROM users WHERE email = ?",
      [email]
    );

    if (existingUser.length > 0) {
      return res.status(400).json({ message: "Email already registered" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const hasShop = shop_name ? 1 : 0;

    // Insert user (includes profile_picture from uploaded file)
    const [result] = await db.execute(
      `INSERT INTO users 
       (username, email, password, phone, shop_name, has_shop, profile_picture, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, NOW())`,
      [
        username,
        email,
        hashedPassword,
        phone || null,
        shop_name || null,
        hasShop,
        profile_picture,
      ]
    );

    const userId = result.insertId;

    // Generate access token
    const accessToken = jwt.sign(
      { id: userId, email, username, hasShop },
      process.env.JWT_SECRET,
      { expiresIn: ACCESS_TOKEN_EXPIRES }
    );

    // Generate refresh token
    const refreshTokenPlain = generateRefreshToken();
    const refreshTokenHashed = hashToken(refreshTokenPlain);
    const expiresAt = new Date(Date.now() + REFRESH_TOKEN_EXPIRES_DAYS * 24 * 60 * 60 * 1000);

    // Store refresh token in database
    await db.execute(
      "INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES (?, ?, ?)",
      [userId, refreshTokenHashed, expiresAt]
    );

    // Send response
    res.status(201).json({
      message: "User registered successfully",
      userId,
      username,
      hasShop,
      profile_picture,
      accessToken,
      refreshToken: refreshTokenPlain,
    });
  } catch (error) {
    console.error("Error registering user:", error);
    res.status(500).json({ message: "Server error" });
  }
};


// LOGIN
export const LoginUser = async (req, res) => {
  // get email and password from request body
  const { email, password } = req.body;
  
  // if email and password field is empty send 400 status 
  if (!email || !password) {
    return res.status(400).json({ message: "All fields are required" });
  }

  try {
    // connect to db
    const db = await connect2DB();
    
    // check if there is a user with the email
    const [user] = await db.execute(
      "SELECT * FROM users WHERE email = ?",
      [email]
    );
    
    // if user does not exist send 404 status
    if (user.length === 0) {
      return res.status(404).json({ message: "Email not found" });
    }
    
    // check if the password is correct
    const validPassword = await bcrypt.compare(password, user[0].password);
    
    // if the password is incorrect send 401 status
    if (!validPassword) {
      return res.status(401).json({ message: "Incorrect password" });
    }
    
    // get user details 
    const userId = user[0].user_id;
    const hasShop = user[0].has_shop;

    // Generate access token
    const accessToken = jwt.sign(
      { id: userId, email: user[0].email, username: user[0].username, hasShop },
      process.env.JWT_SECRET,
      { expiresIn: ACCESS_TOKEN_EXPIRES }
    );

    // Generate refresh token
    const refreshTokenPlain = generateRefreshToken();
    const refreshTokenHashed = hashToken(refreshTokenPlain);
    const expiresAt = new Date(Date.now() + REFRESH_TOKEN_EXPIRES_DAYS * 24 * 60 * 60 * 1000);

    // Store new refresh token in database
    await db.execute(
      "INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES (?, ?, ?)",
      [userId, refreshTokenHashed, expiresAt]
    );
    
    // send response
    res.status(200).json({
      message: "Login successful",
      userId,
      username: user[0].username,
      hasShop,
      accessToken,
      refreshToken: refreshTokenPlain,
    });
  } catch (error) {
    console.error("Error logging in:", error);
    res.status(500).json({ message: "Server error" });
  }
};


// REFRESH ACCESS TOKEN (with token rotation)
export const refreshAccessToken = async (req, res) => {
  const { refreshToken } = req.body;
  
  if (!refreshToken) {
    return res.status(400).json({ message: "Refresh token required" });
  }

  try {
    const db = await connect2DB();
    const hashedToken = hashToken(refreshToken);
    
    // Find and validate refresh token
    const [tokens] = await db.execute(
      "SELECT * FROM refresh_tokens WHERE token = ? AND expires_at > NOW()",
      [hashedToken]
    );
    
    if (tokens.length === 0) {
      return res.status(401).json({ message: "Invalid or expired refresh token" });
    }
    
    const userId = tokens[0].user_id;
    
    // Get user details
    const [user] = await db.execute(
      "SELECT * FROM users WHERE user_id = ?",
      [userId]
    );
    
    // Delete old refresh token (invalidate it)
    await db.execute(
      "DELETE FROM refresh_tokens WHERE token = ?",
      [hashedToken]
    );
    
    // Generate new access token
    const accessToken = jwt.sign(
      { id: user[0].user_id, email: user[0].email, username: user[0].username, hasShop: user[0].has_shop },
      process.env.JWT_SECRET,
      { expiresIn: ACCESS_TOKEN_EXPIRES }
    );
    
    // Generate new refresh token
    const newRefreshTokenPlain = generateRefreshToken();
    const newRefreshTokenHashed = hashToken(newRefreshTokenPlain);
    const expiresAt = new Date(Date.now() + REFRESH_TOKEN_EXPIRES_DAYS * 24 * 60 * 60 * 1000);
    
    // Store new refresh token in database
    await db.execute(
      "INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES (?, ?, ?)",
      [userId, newRefreshTokenHashed, expiresAt]
    );
    
    // Return both new tokens
    res.status(200).json({ 
      accessToken,
      refreshToken: newRefreshTokenPlain 
    });
  } catch (error) {
    console.error("Error refreshing token:", error);
    res.status(500).json({ message: "Server error" });
  }
};


// LOGOUT
export const logoutUser = async (req, res) => {
  const { refreshToken } = req.body;
  
  if (!refreshToken) {
    return res.status(400).json({ message: "Refresh token required" });
  }

  try {
    const db = await connect2DB();
    const hashedToken = hashToken(refreshToken);
    
    // Delete the refresh token from database
    await db.execute(
      "DELETE FROM refresh_tokens WHERE token = ?",
      [hashedToken]
    );
    
    res.status(200).json({ message: "Logged out successfully" });
  } catch (error) {
    console.error("Error logging out:", error);
    res.status(500).json({ message: "Server error" });
  }
};


// GET ALL USERS
export const getAllUsers = async (req, res) => {
  try {
    // connect to database
    const db = await connect2DB();
    
    // query to select all users
    const [users] = await db.execute(
      "SELECT user_id, username, shop_name, has_shop, profile_picture FROM users"
    );
    
    // send users as response in json format
    res.status(200).json(users);
  } catch (error) {
    console.error("Error fetching users:", error);
    res.status(500).json({ message: "Server error" });
  }
};


export const getUserById = async (req, res) => {
  // get user id from req.params
  const { user_id } = req.params; 
  
  try {
    // connect to database
    const db = await connect2DB();

    // query to select user by id - NOW INCLUDES shop_picture
    const [user] = await db.execute(
      "SELECT user_id, username, phone, email, shop_name, has_shop, profile_picture, shop_picture, created_at FROM users WHERE user_id = ?",
      [user_id]
    );
    
    // if user not found send error 404
    if (user.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }
    
    // send user as response
    res.status(200).json(user[0]);  
  } catch (error) {
    console.error("Error fetching user:", error);
    res.status(500).json({ message: "Server error" });
  }
};


// UPDATE USER PROFILE
export const updateUserProfile = async (req, res) => {
  const userId = req.user.id;   
  const { username, phone, shop_name } = req.body;
  
  // Get the Cloudinary URL if file was uploaded
  // Cloudinary stores the URL in req.file.path
  const profile_picture = req.file ? req.file.path : undefined;

  // Check if at least one field is provided
  if (!username && !phone && !shop_name && !profile_picture) {
    return res.status(400).json({ message: "At least one field must be provided to update" });
  }

  try {
    const db = await connect2DB();

    // check if user exists
    const [user] = await db.execute(
      "SELECT * FROM users WHERE user_id = ?", 
      [userId]
    );
    
    if (user.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    // Use existing values if field not provided
    const updatedUsername = username || user[0].username;
    const updatedPhone = phone !== undefined ? phone : user[0].phone;
    const updatedShopName = shop_name !== undefined ? shop_name : user[0].shop_name;
    const updatedHasShop = updatedShopName ? 1 : 0;
    const updatedProfilePicture = profile_picture !== undefined ? profile_picture : user[0].profile_picture;

    // Update user
    await db.execute(
      `UPDATE users 
       SET username = ?, phone = ?, shop_name = ?, has_shop = ?, profile_picture = ?
       WHERE user_id = ?`,
      [updatedUsername, updatedPhone, updatedShopName, updatedHasShop, updatedProfilePicture, userId]
    );

    res.status(200).json({ 
      message: "User updated successfully",
      profile_picture: updatedProfilePicture 
    });
  } catch (error) {
    console.error("Error updating user:", error);
    res.status(500).json({ message: "Server error" });
  }
};
