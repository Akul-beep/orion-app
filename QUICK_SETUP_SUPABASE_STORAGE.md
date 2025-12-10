# ⚡ Quick Setup: Supabase Storage for Email Images

## 🎯 What You're Doing

Uploading your Ory character images and logo to Supabase Storage so they show in emails.

---

## 📦 Step-by-Step (5 minutes)

### 1. Create Bucket
1. Supabase Dashboard → **Storage** (left sidebar)
2. Click **"Create a new bucket"**
3. Name: `email-assets`
4. **Public bucket**: Toggle **ON** ✅
5. Click **"Create"**

### 2. Upload Logo
1. Click `email-assets` bucket
2. Click **"Upload file"**
3. Upload: `assets/logo/app_logo.png`
4. **Right-click** file → **"Copy URL"**
5. Save URL (looks like: `https://xxxxx.supabase.co/storage/v1/object/public/email-assets/app_logo.png`)

### 3. Create Character Folder
1. In `email-assets` bucket
2. Click **"New folder"** or **"Create folder"**
3. Name: `character`
4. Click **"Create"**

### 4. Upload Ory Images
1. Click into `character` folder
2. Upload these 4 files:
   - `ory_friendly.png`
   - `ory_concerned.png`
   - `ory_excited.png`
   - `ory_proud.png`
3. After each upload, **right-click** → **"Copy URL"**
4. Save all 4 URLs

### 5. Update Edge Function
1. Supabase → **Edge Functions** → `send-email`
2. Find lines 10-14 (image URLs)
3. Replace with your copied URLs
4. Click **"Deploy"**

---

## ✅ Done!

Your images are now accessible in emails!

**Full guide**: See `SUPABASE_STORAGE_AND_RESEND_DOMAIN_SETUP.md` for details.
