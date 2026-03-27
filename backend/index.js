import express from "express";
import dotenv from "dotenv";
import connect2DB from "./lib/db.js";
import userRoutes from "./routes/user.route.js";
import shopRoutes from "./routes/shop.route.js";
import productRoutes from "./routes/product.route.js";
import orderRoutes from "./routes/order.route.js";
import cors from "cors";

dotenv.config();

const app = express();
const PORT = process.env.PORT;
app.use(cors());

// Middleware
app.use(express.json());

// port and database connection
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is running on port ${PORT}`);
    connect2DB();
})

app.use('/api/users', userRoutes);
app.use('/api/shops', shopRoutes);
app.use('/api/products', productRoutes);
app.use('/api/orders', orderRoutes);    