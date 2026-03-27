import jwt from "jsonwebtoken";
import dotenv from "dotenv";
dotenv.config();

export const verifyToken = (req, res, next) => {
  // get authorization from the request header
  const authHeader = req.headers.authorization;
  // if there isn't any authorization header i t will send an error message
  if (!authHeader || !authHeader.startsWith("Bearer"))
    return res.status(401).json({ message: "Access token missing" });

  // split the auth header to split the bearer and the token 
  const token = authHeader.split(" ")[1];

  try {
    // verify the token with the secret key and get the payload which will store the user info into the decoded
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    // store the decoded info into req.user
    req.user = decoded;
    // call the next middleware or route handler
    next();
  } catch (err) {
    // send error if token is invalid or expired
    return res.status(401).json({ message: "Invalid or expired token" });
  }
};
