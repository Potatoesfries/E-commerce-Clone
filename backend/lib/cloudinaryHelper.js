import { v2 as cloudinary } from 'cloudinary';

// Helper function to extract public_id from Cloudinary URL
export const getPublicIdFromUrl = (url) => {
    if (!url) return null;
    const matches = url.match(/\/upload\/(?:v\d+\/)?([^\.]+)/);
    return matches ? matches[1] : null;
};

export const deleteFromCloudinary = async (imageUrl) => {
    if (!imageUrl) return;
    try {
        const publicId = getPublicIdFromUrl(imageUrl);
        if (publicId) {
            const result = await cloudinary.uploader.destroy(publicId);
            if (result.result === 'ok') {
                console.log('✅ Deleted image from Cloudinary:', publicId);
            } else if (result.result === 'not found') {
                console.log('ℹ️ Image already deleted or not found:', publicId);
            }
            return result;
        }
    } catch (error) {
        console.error('❌ Failed to delete from Cloudinary:', error);
    }
};