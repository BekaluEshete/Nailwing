import logging

import cloudinary
import cloudinary.uploader
import cloudinary.api
from django.conf import settings
import os

logger = logging.getLogger("authentication")


def configure_cloudinary():
    """Configure Cloudinary with credentials from environment"""
    cloudinary.config(
        cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME", "dpdeewamf"),
        api_key=os.getenv("CLOUDINARY_API_KEY", "421213985844164"),
        api_secret=os.getenv("CLOUDINARY_API_SECRET", "vJNfXKWWyZBju1OuwV8cq4cOUUI"),
        secure=True,
    )


def upload_profile_image(image_file, user_id):
    """
    Upload profile image to Cloudinary
    
    Args:
        image_file: The image file to upload
        user_id: User ID for organizing images
    
    Returns:
        dict: Cloudinary upload response with URL and public_id
    """
    configure_cloudinary()
    
    try:
        # Upload image to Cloudinary
        upload_result = cloudinary.uploader.upload(
            image_file,
            folder=f"nilewing/profiles/{user_id}",
            resource_type="image",
            transformation=[
                {"width": 400, "height": 400, "crop": "fill", "gravity": "face"},
                {"quality": "auto", "fetch_format": "auto"},
            ],
        )
        
        return {
            "success": True,
            "url": upload_result.get("secure_url"),
            "public_id": upload_result.get("public_id"),
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
        }


def delete_profile_image(public_id):
    """
    Delete image from Cloudinary
    
    Args:
        public_id: Cloudinary public_id of the image to delete
    
    Returns:
        bool: True if successful, False otherwise
    """
    configure_cloudinary()
    
    try:
        if public_id:
            cloudinary.uploader.destroy(public_id)
        return True
    except Exception as e:
        logger.error("Error deleting image from Cloudinary (public_id=%s): %s", public_id, e)
        return False

