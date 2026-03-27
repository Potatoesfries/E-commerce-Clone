import cloudinary from "../lib/cloudinary.js";
import { CloudinaryStorage } from "multer-storage-cloudinary";
import multer from "multer";

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: "ProductManagement", // creates a folder in Cloudinary
    format: async (req, file) => "png",
    public_id: (req, file) => Date.now() + "-" + file.originalname, // unique file name
  },
});

const parser = multer({ storage });

export default parser;
