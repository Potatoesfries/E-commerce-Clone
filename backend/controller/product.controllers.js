import connect2DB from "../lib/db.js";

// CREATE PRODUCT
export const createProduct = async (req, res) => {
    const userId = req.user.id;
    const { product_name, description, price, stock, category } = req.body; // Add category
    const product_image = req.file ? req.file.path : null;

    // Validate required fields (including category)
    if (!product_name || !price || !product_image || !category) {
        return res.status(400).json({ 
            message: "Product name, price, category, and image are required" 
        });
    }

    // Validate category is one of the allowed values
    const validCategories = [
        'Electronics',
        'Fashion & Clothing',
        'Home & Living',
        'Books & Education',
        'Sports & Fitness',
        'Beauty & Health'
    ];
    
    if (!validCategories.includes(category)) {
        return res.status(400).json({ 
            message: "Invalid category selected" 
        });
    }

    try {
        const db = await connect2DB();

        const [result] = await db.execute(
            `INSERT INTO products 
                (user_id, shop_name, product_name, description, price, stock, product_image, category)
             VALUES (?, (SELECT shop_name FROM users WHERE user_id = ?), ?, ?, ?, ?, ?, ?)`,
            [userId, userId, product_name, description || null, price, stock || 0, product_image, category]
        );

        res.status(201).json({
            message: "Product created successfully",
            productId: result.insertId,
        });
    } catch (error) {
        console.error("Error creating product:", error);
        res.status(500).json({ message: "Server error" });
    }
};

// GET ALL PRODUCTS BY USER
export const getProductsByUser = async (req, res) => {
    const userId = req.user.id;

    try {
        const db = await connect2DB();
        const [products] = await db.execute(
            "SELECT * FROM products WHERE user_id = ? AND is_deleted = 0",
            [userId]
        );
        res.status(200).json(products);
    } catch (error) {
        console.error("Error fetching products:", error);
        res.status(500).json({ message: "Server error" });
    }
};

// GET PRODUCT BY ID
export const getProductById = async (req, res) => {
    const { product_id } = req.params;
    try {
        const db = await connect2DB();
        const [products] = await db.execute(
            "SELECT * FROM products WHERE product_id = ? AND is_deleted = 0",
            [product_id]
        );
        if (products.length === 0) return res.status(404).json({ message: "Product not found" });
        res.status(200).json(products[0]);
    } catch (error) {
        console.error("Error fetching product:", error);
        res.status(500).json({ message: "Server error" });
    }
};

// GET ALL PRODUCTS (for public page)
export const getAllProducts = async (req, res) => {
    try {
        const db = await connect2DB();
        const [products] = await db.execute(
            `SELECT 
                p.*, 
                u.shop_name, 
                u.shop_picture,
                u.user_id as owner_id
             FROM products p 
             JOIN users u ON p.user_id = u.user_id 
             WHERE p.is_deleted = 0 
             ORDER BY p.created_at DESC`
        ); 
        res.status(200).json(products);
    } catch (error) {
        console.error("Error fetching all products:", error);
        res.status(500).json({ message: "Server error" }); 
    }
};

// UPDATE PRODUCT
export const updateProduct = async (req, res) => {
    const userId = req.user.id;
    const { product_id } = req.params;
    const { product_name, description, price, stock, category } = req.body; 
    const product_image = req.file ? req.file.path : null;

    try {
        const db = await connect2DB();

        const [existing] = await db.execute(
            "SELECT * FROM products WHERE product_id = ? AND user_id = ?",
            [product_id, userId]
        );
        
        if (existing.length === 0) {
            return res.status(404).json({ message: "Product not found or not yours" });
        }

        // Validate category if provided
        if (category) {
            const validCategories = [
                'Electronics',
                'Fashion & Clothing',
                'Home & Living',
                'Books & Education',
                'Sports & Fitness',
                'Beauty & Health'
            ];
            
            if (!validCategories.includes(category)) {
                return res.status(400).json({ message: "Invalid category" });
            }
        }

        await db.execute(
            `UPDATE products SET 
                product_name = ?, 
                description = ?, 
                price = ?, 
                stock = ?,
                category = ?,
                product_image = COALESCE(?, product_image)
             WHERE product_id = ?`,
            [
                product_name || existing[0].product_name, 
                description || existing[0].description, 
                price || existing[0].price, 
                stock || existing[0].stock,
                category || existing[0].category,
                product_image, 
                product_id
            ]
        );

        res.status(200).json({ message: "Product updated successfully" });
    } catch (error) {
        console.error("Error updating product:", error);
        res.status(500).json({ message: "Server error" });
    }
};

// DELETE PRODUCT
export const deleteProduct = async (req, res) => {
    const userId = req.user.id;
    const { product_id } = req.params;

    try {
        const db = await connect2DB();

        // Check if product belongs to the user
        const [existing] = await db.execute(
            "SELECT * FROM products WHERE product_id = ? AND user_id = ? AND is_deleted = 0",
            [product_id, userId]
        );
        
        if (existing.length === 0) {
            return res.status(404).json({ message: "Product not found or not yours" });
        }

        // Soft delete: mark as deleted instead of removing
        const [result] = await db.execute(
            "UPDATE products SET is_deleted = 1 WHERE product_id = ?",
            [product_id]
        );

        console.log('✅ Soft delete result:', result);

        res.status(200).json({ message: "Product deleted successfully" });
    } catch (error) {
        console.error("❌ Error deleting product:", error);
        res.status(500).json({ 
            message: "Server error", 
            error: error.message,
            details: process.env.NODE_ENV === 'development' ? error.stack : undefined
        });
    }
};

// GET PRODUCTS BY CATEGORY (add this new function)
export const getProductsByCategory = async (req, res) => {
    const { category } = req.params;
    
    try {
        const db = await connect2DB();
        const [products] = await db.execute(
            `SELECT p.*, u.shop_name, u.profile_picture AS shop_profile_picture 
             FROM products p 
             JOIN users u ON p.user_id = u.user_id 
             WHERE p.category = ? AND p.is_deleted = 0
             ORDER BY p.created_at DESC`,
            [category]
        );
        res.status(200).json(products);
    } catch (error) {
        console.error("Error fetching products by category:", error);
        res.status(500).json({ message: "Server error" });
    }
};