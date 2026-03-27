import Router from "express";
import {
    createProduct,
    getProductsByUser,
    getProductById,
    getAllProducts,
    updateProduct,
    deleteProduct,
    getProductsByCategory
} from "../controller/product.controllers.js";
import { verifyToken } from "../middleware/auth.js";
import parser from "../middleware/upload.js";

const router = Router();

router.post("/create", verifyToken, parser.single("product_image"), createProduct); 
router.get("/my-products", verifyToken, getProductsByUser);
// IMPORTANT: More specific routes must come BEFORE generic ones
router.get("/all", getAllProducts);
router.get("/category/:category", getProductsByCategory); // Fixed path
router.get("/:product_id", getProductById);
router.put("/update/:product_id", verifyToken, parser.single("product_image"), updateProduct);
router.delete("/delete/:product_id", verifyToken, deleteProduct);

export default router;