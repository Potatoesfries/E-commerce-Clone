import connect2DB from "../lib/db.js";
import { deleteFromCloudinary } from "../lib/cloudinaryHelper.js";

export const createShop = async (req, res) => {
  const { shop_name } = req.body;
  const user_id = req.user.id;
  
  console.log('📝 Create Shop Request:', { shop_name, user_id, hasFile: !!req.file });
  
  if (!shop_name) {
    return res.status(400).json({ message: "Shop name is required" });
  }

  try {
    const db = await connect2DB();

    const [rows] = await db.execute(
      "SELECT has_shop FROM users WHERE user_id = ?",
      [user_id]
    );
    
    if (rows.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }
    
    if (rows[0].has_shop) {
      return res.status(400).json({ message: "User already has a shop" });
    }

    const imageUrl = req.file ? req.file.path : null;
    console.log('🖼️ Image URL:', imageUrl);

    await db.execute(
      "UPDATE users SET shop_name = ?, has_shop = 1, shop_picture = ? WHERE user_id = ?",
      [shop_name, imageUrl, user_id]
    );

    console.log('✅ Shop created successfully');

    res.status(201).json({
      message: "Shop created successfully",
      shopName: shop_name,
      shopPicture: imageUrl,
      ownerId: user_id,
    });
  } catch (error) {
    if (error.code === "ER_DUP_ENTRY") {
      return res.status(400).json({ message: "Shop name already taken" });
    }
    console.error("❌ Error creating shop:", error);
    res.status(500).json({ 
      message: "Internal server error",
      error: error.message 
    });
  }
};

export const updateShop = async (req, res) => {
  const { shop_name } = req.body;
  const user_id = req.user.id;
  const imageUrl = req.file ? req.file.path : null;

  if (!shop_name && !imageUrl) {
    return res.status(400).json({
      message: "Shop name or image is required to update",
    });
  }

  try {
    const db = await connect2DB();

    const [rows] = await db.execute(
      "SELECT has_shop, shop_picture FROM users WHERE user_id = ?",
      [user_id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    if (!rows[0].has_shop) {
      return res.status(400).json({ message: "User does not have a shop" });
    }

    // If updating image, delete old one from Cloudinary
    if (imageUrl && rows[0].shop_picture) {
      await deleteFromCloudinary(rows[0].shop_picture);
    }

    await db.execute(
      "UPDATE users SET shop_name = IFNULL(?, shop_name), shop_picture = IFNULL(?, shop_picture) WHERE user_id = ?",
      [shop_name, imageUrl, user_id]
    );

    res.status(200).json({
      message: "Shop updated successfully",
      ...(shop_name && { shopName: shop_name }),
      ...(imageUrl && { shopPicture: imageUrl }),
    });
  } catch (error) {
    console.error("Error updating shop:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const deleteShop = async (req, res) => {
  const user_id = req.user.id;
  
  try {
    const db = await connect2DB();
    
    const [rows] = await db.execute(
      "SELECT has_shop, shop_picture FROM users WHERE user_id = ?",
      [user_id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: "User not found" });
    }

    if (!rows[0].has_shop) {
      return res.status(400).json({ message: "User does not have a shop" });
    }

    // Get all product images before deleting
    const [products] = await db.execute(
      "SELECT product_image FROM products WHERE user_id = ?",
      [user_id]
    );

    // Delete all product images from Cloudinary
    for (const product of products) {
      await deleteFromCloudinary(product.product_image);
    }

    // Delete shop picture from Cloudinary
    if (rows[0].shop_picture) {
      await deleteFromCloudinary(rows[0].shop_picture);
    }

    // Get a connection for transaction
    const connection = await db.getConnection();
    
    try {
      // Start transaction
      await connection.beginTransaction();

      // Delete all products
      await connection.execute(
        "DELETE FROM products WHERE user_id = ?",
        [user_id]
      );

      // Delete shop info
      await connection.execute(
        "UPDATE users SET shop_name = NULL, has_shop = 0, shop_picture = NULL WHERE user_id = ?",
        [user_id]
      );

      // Commit transaction
      await connection.commit();

      res.status(200).json({ 
        message: "Shop and all products deleted successfully" 
      });
    } catch (error) {
      // Rollback on error
      await connection.rollback();
      throw error;
    } finally {
      // Always release the connection
      connection.release();
    }

  } catch (error) {
    console.error("Error deleting shop:", error);
    res.status(500).json({ 
      message: "Internal server error",
      error: error.message 
    });
  }
};