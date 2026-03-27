import Router from "express";
import { addToCart , buyProducts, getCart, getCartTotal, deleteCartItem, updateCartItem, getUserOrders} from "../controller/order.controllers.js";
import { verifyToken } from "../middleware/auth.js";

const router = Router();

router.post("/add-to-cart", verifyToken, addToCart);
router.post('/buyProduct', verifyToken, buyProducts);
router.get('/getOrders', verifyToken, getCart);
router.get('/getCartTotal', verifyToken, getCartTotal);
router.post('/removeFromCart', verifyToken, deleteCartItem);
router.put('/updateCartItem', verifyToken, updateCartItem);
router.get("/my-orders", verifyToken, getUserOrders);

export default router;