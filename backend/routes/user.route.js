import Router from 'express';
import { 
  RegisterUser, 
  LoginUser, 
  getAllUsers, 
  getUserById, 
  updateUserProfile,
  refreshAccessToken,
  logoutUser 
} from '../controller/user.controllers.js';
import { verifyToken } from '../middleware/auth.js';
import parser from "../middleware/upload.js";

const router = Router();

// Public routes
router.get('/', getAllUsers);
router.get('/:user_id', getUserById);
router.post("/register", parser.single("image"), RegisterUser);
router.post('/login', LoginUser);
router.post('/refresh', refreshAccessToken);
router.post('/logout', logoutUser);

// Protected routes
router.put('/update-profile', verifyToken, parser.single("image"), updateUserProfile);

export default router;