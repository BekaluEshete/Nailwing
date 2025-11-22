# 👤 Profile Section Implementation with Cloudinary

## ✅ Implementation Complete

### Backend Changes

#### 1. **Cloudinary Service** (`Backend/authentication/cloudinary_service.py`)

- Configured Cloudinary with provided credentials
- `upload_profile_image()` - Uploads images to Cloudinary with automatic transformations
- `delete_profile_image()` - Deletes old images when updating profile
- Images are organized in folders: `nilewing/profiles/{user_id}/`
- Automatic image optimization (400x400, face detection, auto quality)

#### 2. **User Model Updates** (`Backend/authentication/models.py`)

- Added `profile_image_url` - Stores Cloudinary URL
- Added `cloudinary_public_id` - Stores Cloudinary public ID for deletion

#### 3. **Profile Endpoint** (`Backend/authentication/views.py`)

- Updated `profile()` action to handle Cloudinary uploads
- Automatically deletes old image when uploading new one
- Handles both GET (retrieve) and PATCH (update) requests
- Returns Cloudinary URL in response

#### 4. **Serializer Updates** (`Backend/authentication/serializers.py`)

- `UserProfileSerializer` now returns Cloudinary URL in `profileImage` field
- Added `profileImageUrl` field for explicit Cloudinary URL
- Falls back to local image URL if Cloudinary URL not available

#### 5. **Database Migration** (`Backend/authentication/migrations/0003_add_cloudinary_fields.py`)

- Migration file created for new Cloudinary fields

#### 6. **Dependencies** (`Backend/requirements.txt`)

- Added `cloudinary` and `python-cloudinary` packages

### Frontend Changes

#### 1. **User Model** (`Frontend/nilewing/lib/features/user/model/user_model.dart`)

- `UserProfile` class with all profile fields
- Handles Cloudinary URL from backend
- JSON serialization/deserialization

#### 2. **User Service** (`Frontend/nilewing/lib/features/user/service/user_service.dart`)

- `getProfile()` - Fetches user profile from API
- `updateProfile()` - Updates profile with multipart request for image upload
- Handles JWT authentication tokens

#### 3. **User View Model** (`Frontend/nilewing/lib/features/user/viewmodel/user_view_model.dart`)

- Manages profile state
- Image picker integration (gallery & camera)
- Form validation
- Loading and error states

#### 4. **Profile Screen** (`Frontend/nilewing/lib/features/user/view/profile_screen.dart`)

- Beautiful UI with profile image display
- Image picker with options (Gallery, Camera, Remove)
- Form fields for all profile data
- Real-time validation
- Success/error feedback

#### 5. **Routing** (`Frontend/nilewing/lib/core/routes/app_router.dart`)

- Added `/profile` route
- Protected route (requires authentication)

## 🔧 Setup Instructions

### Backend Setup

1. **Install Cloudinary package:**

   ```bash
   cd Backend
   pip install -r requirements.txt
   ```

2. **Set Environment Variables** (for production):

   ```bash
   CLOUDINARY_CLOUD_NAME=dpdeewamf
   CLOUDINARY_API_KEY=421213985844164
   CLOUDINARY_API_SECRET=vJNfXKWWyZBju1OuwV8cq4cOUUI
   ```

   Or use the CLOUDINARY_URL format:

   ```bash
   CLOUDINARY_URL=cloudinary://421213985844164:vJNfXKWWyZBju1OuwV8cq4cOUUI@dpdeewamf
   ```

3. **Run Migration:**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

### Frontend Setup

1. **Dependencies are already included:**

   - `image_picker` - For selecting images
   - `http` - For API calls
   - `shared_preferences` - For token storage

2. **No additional setup needed!**

## 📱 Usage

### Accessing Profile Screen

Navigate to `/profile` route:

```dart
context.go('/profile');
```

### Profile Features

1. **View Profile:**

   - Automatically loads user profile on screen open
   - Displays profile image from Cloudinary
   - Shows all user information

2. **Update Profile Image:**

   - Tap the camera icon on profile image
   - Choose from Gallery or Camera
   - Image is automatically uploaded to Cloudinary
   - Old image is deleted from Cloudinary

3. **Update Profile Information:**
   - Edit any field (name, age, gender, nationality, language)
   - Form validation ensures data integrity
   - Click "Save Changes" to update
   - Success/error messages displayed

## 🔐 Cloudinary Configuration

### Credentials Used:

- **Cloud Name:** `dpdeewamf`
- **API Key:** `421213985844164`
- **API Secret:** `vJNfXKWWyZBju1OuwV8cq4cOUUI`

### Image Transformations:

- **Size:** 400x400 pixels
- **Crop:** Fill with face detection
- **Quality:** Auto-optimized
- **Format:** Auto (WebP when supported)

### Storage Structure:

```
nilewing/
  └── profiles/
      └── {user_id}/
          └── {image_name}
```

## 🧪 Testing

### Test Profile Image Upload:

1. Navigate to Profile screen
2. Tap camera icon on profile image
3. Select image from gallery or take photo
4. Image should appear immediately
5. Click "Save Changes"
6. Verify image is uploaded to Cloudinary
7. Refresh app - image should persist

### Test Profile Update:

1. Edit any profile field
2. Click "Save Changes"
3. Verify success message
4. Refresh app - changes should persist

### Test Error Handling:

1. Try updating with invalid data
2. Verify error messages display
3. Try uploading very large image
4. Verify appropriate error handling

## 📝 API Endpoints

### GET `/api/auth/profile/`

**Headers:**

```
Authorization: Bearer {access_token}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "fullName": "John Doe",
    "email": "john@example.com",
    "age": 25,
    "gender": "male",
    "nationality": "USA",
    "language": "English",
    "profileImageUrl": "https://res.cloudinary.com/dpdeewamf/image/upload/...",
    "rememberMe": false,
    "date_joined": "2024-01-01T00:00:00Z"
  }
}
```

### PATCH `/api/auth/profile/`

**Headers:**

```
Authorization: Bearer {access_token}
Content-Type: multipart/form-data
```

**Form Data:**

- `fullName` (optional)
- `age` (optional)
- `gender` (optional: "male", "female", "other")
- `nationality` (optional)
- `language` (optional)
- `profileImage` (optional: file)

**Response:**

```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": 1,
    "fullName": "John Doe",
    "email": "john@example.com",
    "age": 26,
    "gender": "male",
    "nationality": "USA",
    "language": "English",
    "profileImageUrl": "https://res.cloudinary.com/dpdeewamf/image/upload/...",
    "rememberMe": false,
    "date_joined": "2024-01-01T00:00:00Z"
  }
}
```

## 🎨 UI Features

- **Profile Image:**

  - Circular display with border
  - Shadow effect
  - Camera icon overlay for editing
  - Default avatar when no image

- **Form Fields:**

  - Full Name (required)
  - Age (optional, validated)
  - Gender (dropdown)
  - Nationality (optional)
  - Language (optional)

- **User Experience:**
  - Loading indicators
  - Error messages
  - Success notifications
  - Form validation
  - Image preview before upload

## ✅ Status

All features implemented and ready for testing!

- ✅ Cloudinary integration
- ✅ Image upload/delete
- ✅ Profile CRUD operations
- ✅ Form validation
- ✅ Error handling
- ✅ UI/UX polish
- ✅ Route protection

---

**Profile section is fully functional with Cloudinary photo storage! 📸**
