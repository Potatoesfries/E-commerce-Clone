import Router from 'express';
import { createShop, updateShop, deleteShop } from '../controller/shop.controllers.js';
import { verifyToken } from '../middleware/auth.js';
import parser from "../middleware/upload.js";
    

const router = Router();
router.post("/createShop", verifyToken, parser.single("image"), createShop);
router.post("/updateShop", verifyToken, parser.single("image"), updateShop);
router.delete("/deleteShop", verifyToken, deleteShop);


export default router;