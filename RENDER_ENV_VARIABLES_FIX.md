# Render Environment Variables - Fixes Required

## Current Issues Found

Based on your Render environment variables, here are the issues that need to be fixed:

### ❌ **Critical Issues:**

1. **`DEBUG=True`** - Should be `False` for production
2. **`REDIS_URL=redis://redis:6379/1`** - This won't work on Render (Docker-compose format)
3. **`SECRET_KEY=django-insecure-key`** - Insecure default key

### ⚠️ **Recommendations:**

4. **`ALLOWED_HOSTS=*`** - Works but less secure (should specify exact hostname)

---

## 🔧 Required Fixes

### 1. Fix DEBUG Setting

**Change:**

```
DEBUG = True
```

**To:**

```
DEBUG = False
```

**Why:** Debug mode exposes sensitive information and should never be enabled in production.

---

### 2. Fix REDIS_URL

**Current (WRONG):**

```
REDIS_URL = redis://redis:6379/1
```

**Options:**

#### Option A: Use Render Redis Service (Recommended)

1. Go to your Render Dashboard
2. Create a new **Redis** service
3. After creation, Render will provide a Redis URL like:
   ```
   redis://red-xxxxx:6379
   ```
4. Use that URL:
   ```
   REDIS_URL = redis://red-xxxxx:6379/0
   ```
   (Add `/0` for database 0, `/1` for database 1, etc.)

#### Option B: Use External Redis (e.g., Upstash)

1. Sign up for Upstash Redis (free tier available)
2. Create a Redis database
3. Copy the connection URL
4. Use it as `REDIS_URL`

#### Option C: Temporarily Disable Redis (If you don't need chat/websockets)

If you're not using WebSocket chat features, you can temporarily disable Redis, but this will break chat functionality.

---

### 3. Generate a Secure SECRET_KEY

**Current (INSECURE):**

```
SECRET_KEY = django-insecure-key
```

**How to Generate a New Secret Key:**

**Option A: Use Python (Recommended)**

```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

**Option B: Use Online Generator**

- Visit: https://djecrety.ir/ (Django secret key generator)

**Option C: Use OpenSSL**

```bash
openssl rand -base64 50
```

**Then set in Render:**

```
SECRET_KEY = <generated-secret-key>
```

**Example output:**

```
SECRET_KEY = djangoproject-django-insecure-1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t1u2v3w4x5y6z
```

---

### 4. Fix ALLOWED_HOSTS (Optional but Recommended)

**Current:**

```
ALLOWED_HOSTS = *
```

**Better (More Secure):**

```
ALLOWED_HOSTS = nilewing-backend.onrender.com
```

Or if you have multiple domains:

```
ALLOWED_HOSTS = nilewing-backend.onrender.com,localhost,127.0.0.1
```

**Note:** The `*` works but is less secure. Specifying exact hostnames is better.

---

## ✅ Corrected Environment Variables

Here's what your Render environment variables should look like:

```
ALLOWED_HOSTS = nilewing-backend.onrender.com
DATABASE_URL = postgresql://neondb_owner:npg_3be1SFAkKJZv@ep-small-nine-adw07k0.pooler.ap-southeast-1.aws.neon.tech/neondb
DEBUG = False
REDIS_URL = redis://red-xxxxx:6379/0
SECRET_KEY = <your-generated-secret-key>
```

---

## 📝 Step-by-Step Fix Instructions

1. **Go to Render Dashboard** → Your Web Service → **Environment** tab

2. **Update DEBUG:**

   - Change `DEBUG` from `True` to `False`
   - Click "Save Changes"

3. **Create Redis Service:**

   - Click "New +" → "Redis"
   - Choose a name (e.g., "nilewing-redis")
   - Select the same region as your web service
   - Click "Create Redis"
   - Copy the **Internal Redis URL** (starts with `redis://red-`)
   - Update `REDIS_URL` in your web service's environment variables
   - Add database number: `redis://red-xxxxx:6379/0` (or `/1` for database 1)

4. **Generate and Update SECRET_KEY:**

   - Run the Python command above to generate a secret key
   - Copy the generated key
   - Update `SECRET_KEY` in Render environment variables

5. **Update ALLOWED_HOSTS (Optional):**

   - Change from `*` to `nilewing-backend.onrender.com`

6. **Redeploy:**
   - After saving all changes, Render will automatically redeploy
   - Or click "Manual Deploy" → "Deploy latest commit"

---

## 🔍 How to Verify Redis Connection

After setting up Redis, check your Render logs to verify it's connecting:

1. Go to your Web Service → **Logs** tab
2. Look for any Redis connection errors
3. If you see "Connection refused" or similar, the Redis URL is incorrect

---

## ⚠️ Important Notes

- **Never commit SECRET_KEY to Git** - Always use environment variables
- **DEBUG=False in production** - Always disable debug mode
- **Redis is required** for WebSocket chat functionality
- After changing environment variables, your service will automatically redeploy

---

## 🆘 If You Don't Have Redis Yet

If you're not ready to set up Redis:

1. **Chat/WebSocket features will not work** without Redis
2. You can still test authentication, flights, matching, etc.
3. To temporarily disable Redis requirements, you'd need to modify the code (not recommended)

**Better solution:** Set up Redis (it's free on Render and quick to configure).
