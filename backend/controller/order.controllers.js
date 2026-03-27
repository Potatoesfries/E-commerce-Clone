import connect2DB from "../lib/db.js";

export const addToCart = async (req, res) => {
    const userId = req.user.id;
    const { product_id, quantity } = req.body;

    if (!quantity || quantity < 1) return res.status(400).json({ message: "Invalid quantity" });

    try {
        const db = await connect2DB();

        // Check if trying to buy own product
        const [product] = await db.execute(
            "SELECT * FROM products WHERE product_id = ?",
            [product_id]
        );
        if (!product[0]) return res.status(404).json({ message: "Product not found" });
        if (product[0].user_id === userId) return res.status(400).json({ message: "Cannot add your own product to cart" });

        // Check if product is already in cart
        const [existingCart] = await db.execute(
            "SELECT * FROM cart WHERE user_id = ? AND product_id = ?",
            [userId, product_id]
        );

        if (existingCart.length > 0) {
            // Update quantity
            await db.execute(
                "UPDATE cart SET quantity = quantity + ? WHERE cart_id = ?",
                [quantity, existingCart[0].cart_id]
            );
        } else {
            // Insert new cart item
            await db.execute(
                "INSERT INTO cart (user_id, product_id, quantity) VALUES (?, ?, ?)",
                [userId, product_id, quantity]
            );
        }

        res.status(200).json({ message: "Product added to cart" });
    } catch (error) {
        console.error("Error adding to cart:", error);
        res.status(500).json({ message: "Server error" });
    }
};

export const buyProducts = async (req, res) => {
    const userId = req.user.id;
    const { cart_ids } = req.body;

    if (!cart_ids || !Array.isArray(cart_ids) || cart_ids.length === 0) {
        return res.status(400).json({ message: "No items selected for purchase" });
    }

    try {
        const db = await connect2DB();

        // Get selected cart items
        const [cartItems] = await db.query(
            `SELECT c.*, p.price, p.stock, p.user_id AS owner_id
             FROM cart c 
             JOIN products p ON c.product_id = p.product_id
             WHERE c.user_id = ? AND c.cart_id IN (?)`,
            [userId, cart_ids]
        );

        if (cartItems.length === 0) return res.status(400).json({ message: "No valid items found in cart" });

        let totalAmount = 0;

        // Validate stock & ownership
        for (let item of cartItems) {
            if (item.owner_id === userId) return res.status(400).json({ message: "Cannot buy your own product" });
            if (item.quantity > item.stock) return res.status(400).json({ message: `Not enough stock for product ${item.product_id}` });
            totalAmount += item.quantity * item.price;
        }

        // Create order
        const [orderResult] = await db.execute(
            "INSERT INTO orders (user_id, total_amount) VALUES (?, ?)",
            [userId, totalAmount]
        );
        const orderId = orderResult.insertId;

// Insert order items + update stock + increment sold count
for (let item of cartItems) {
    await db.execute(
        "INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?, ?, ?, ?)",
        [orderId, item.product_id, item.quantity, item.price]
    );

    await db.execute(
        "UPDATE products SET stock = stock - ?, sold = sold + ? WHERE product_id = ?",
        [item.quantity, item.quantity, item.product_id]
    );
}

        // Remove only purchased items from cart
        await db.query("DELETE FROM cart WHERE cart_id IN (?) AND user_id = ?", [cart_ids, userId]);

        res.status(200).json({ message: "Selected purchase successful", orderId });
    } catch (error) {
        console.error("Error processing purchase:", error);
        res.status(500).json({ message: "Server error" });
    }
};

export const getCart = async (req, res) => {
  const userId = req.user.id;
  try {
    const db = await connect2DB();
    const [cartItems] = await db.execute(
      `SELECT c.cart_id, c.quantity,
              p.product_id, p.product_name, p.price, p.product_image
       FROM cart c 
       JOIN products p ON c.product_id = p.product_id
       WHERE c.user_id = ?`,
      [userId]
    );
    res.status(200).json(cartItems);
  } catch (error) {
    console.error("Error fetching cart:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const deleteCartItem = async (req, res) => {
  const userId = req.user.id;
  const { cart_id } = req.body; 

  console.log('Delete cart item request:', { cart_id, userId }); 

  if (!cart_id) return res.status(400).json({ message: "cart_id is required" });

  try {
    const db = await connect2DB();

    const [result] = await db.execute(
      "DELETE FROM cart WHERE cart_id = ? AND user_id = ?",
      [cart_id, userId]
    );

    console.log('Delete result:', result); 

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Cart item not found" });
    }

    res.status(200).json({ message: "Cart item deleted successfully" });
  } catch (error) {
    console.error("Error deleting cart item:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const getCartTotal = async (req, res) => {
  const userId = req.user.id;

  try {
    const db = await connect2DB();

    const [cartItems] = await db.execute(
      `SELECT c.cart_id, c.quantity,
              p.product_id, p.product_name, 
              CAST(p.price AS DECIMAL(10,2)) as price, 
              p.product_image,
              CAST((c.quantity * p.price) AS DECIMAL(10,2)) AS total_price_per_item
       FROM cart c
       JOIN products p ON c.product_id = p.product_id
       WHERE c.user_id = ?`,
      [userId]
    );

    // Calculate total price of the cart with proper decimal handling
    const cartTotal = cartItems.reduce((sum, item) => {
      const itemTotal = parseFloat(item.total_price_per_item) || 0;
      return sum + itemTotal;
    }, 0);

    // Format the response with proper number types
    const formattedCartItems = cartItems.map(item => ({
      ...item,
      price: parseFloat(item.price),
      total_price_per_item: parseFloat(item.total_price_per_item)
    }));

    res.status(200).json({ 
      cartItems: formattedCartItems, 
      cartTotal: parseFloat(cartTotal.toFixed(2))
    });
  } catch (error) {
    console.error("Error fetching cart:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const updateCartItem = async (req, res) => {
  const userId = req.user.id;
  const { cart_id, quantity } = req.body;

  if (!quantity || quantity < 1) {
    return res.status(400).json({ message: "Invalid quantity" });
  }

  try {
    const db = await connect2DB();

    // Get cart item and product stock
    const [cartItems] = await db.execute(
      `SELECT c.cart_id, c.user_id, p.stock
       FROM cart c 
       JOIN products p ON c.product_id = p.product_id
       WHERE c.cart_id = ? AND c.user_id = ?`,
      [cart_id, userId]
    );

    if (cartItems.length === 0) {
      return res.status(404).json({ message: "Cart item not found" });
    }

    const cartItem = cartItems[0];

    // Check stock
    if (quantity > cartItem.stock) {
      return res.status(400).json({ message: `Only ${cartItem.stock} items available in stock` });
    }

    // Update quantity
    await db.execute(
      "UPDATE cart SET quantity = ? WHERE cart_id = ? AND user_id = ?",
      [quantity, cart_id, userId]
    );

    res.status(200).json({ message: "Cart updated successfully" });
  } catch (error) {
    console.error("Error updating cart:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const getUserOrders = async (req, res) => {
  const userId = req.user.id;

  try {
    const db = await connect2DB();

    const [orders] = await db.execute(
      `SELECT o.order_id, o.total_amount, o.created_at,
              GROUP_CONCAT(
                JSON_OBJECT(
                  'product_name', p.product_name,
                  'quantity', oi.quantity,
                  'price', oi.price,
                  'product_image', p.product_image
                )
              ) as items
       FROM orders o
       LEFT JOIN order_items oi ON o.order_id = oi.order_id
       LEFT JOIN products p ON oi.product_id = p.product_id
       WHERE o.user_id = ?
       GROUP BY o.order_id
       ORDER BY o.created_at DESC`,
      [userId]
    );

    const formattedOrders = orders.map(order => ({
      ...order,
      items: order.items ? JSON.parse(`[${order.items}]`) : []
    }));

    res.status(200).json({ success: true, orders: formattedOrders });
  } catch (error) {
    console.error("Error fetching user orders:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};