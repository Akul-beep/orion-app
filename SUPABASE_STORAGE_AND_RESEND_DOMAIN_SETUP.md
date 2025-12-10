# 📦 Supabase Storage & Resend Domain Setup

## Part 1: Supabase Storage Bucket Setup (For Ory Images)

### Step 1: Create Storage Bucket

1. Go to **Supabase Dashboard** → **Storage** (left sidebar)
2. Click **"Create a new bucket"** button
3. Fill in:
   - **Name**: `email-assets` (or `orion-email-assets`)
   - **Public bucket**: Toggle **ON** (this is important!)
   - **File size limit**: Leave default (50MB is fine)
   - **Allowed MIME types**: Leave empty (allows all types)
4. Click **"Create bucket"**

### Step 2: Upload Logo

1. Click on the `email-assets` bucket you just created
2. Click **"Upload file"** button
3. Navigate to: `assets/logo/app_logo.png` in your project
4. Upload it
5. After upload, **right-click** on `app_logo.png` → **"Copy URL"**
6. The URL will look like:
   ```
   https://lpchovurnlmucwzaltvz.supabase.co/storage/v1/object/public/email-assets/app_logo.png
   ```
7. **Save this URL!**

### Step 3: Create Character Folder

1. Still in the `email-assets` bucket
2. Click **"New folder"** button (or "Create folder")
3. Name it: `character`
4. Click **"Create"** or press Enter

### Step 4: Upload Ory Character Images

1. Click into the `character` folder
2. Upload these 4 files (one by one):
   - `assets/character/ory_friendly.png`
   - `assets/character/ory_concerned.png`
   - `assets/character/ory_excited.png`
   - `assets/character/ory_proud.png`
3. After each upload, **right-click** on the file → **"Copy URL"**
4. **Save all 4 URLs!**

### Step 5: Update Edge Function with URLs

1. Go to **Supabase Dashboard** → **Edge Functions** → Click `send-email`
2. Find these lines (around line 7-14):
   ```typescript
   const IMAGE_BASE_URL = Deno.env.get('IMAGE_BASE_URL') || 'https://your-cdn.com/images'
   const ORION_LOGO_URL = `${IMAGE_BASE_URL}/logo/app_logo.png`
   const ORY_FRIENDLY_URL = `${IMAGE_BASE_URL}/character/ory_friendly.png`
   ```
3. **Replace** with your actual Supabase Storage URLs:
   ```typescript
   // Replace YOUR_PROJECT_REF with your Supabase project reference
   // You can find it in your Supabase URL: https://YOUR_PROJECT_REF.supabase.co
   const ORION_LOGO_URL = 'https://lpchovurnlmucwzaltvz.supabase.co/storage/v1/object/public/email-assets/app_logo.png'
   const ORY_FRIENDLY_URL = 'https://lpchovurnlmucwzaltvz.supabase.co/storage/v1/object/public/email-assets/character/ory_friendly.png'
   const ORY_CONCERNED_URL = 'https://lpchovurnlmucwzaltvz.supabase.co/storage/v1/object/public/email-assets/character/ory_concerned.png'
   const ORY_EXCITED_URL = 'https://lpchovurnlmucwzaltvz.supabase.co/storage/v1/object/public/email-assets/character/ory_excited.png'
   const ORY_PROUD_URL = 'https://lpchovurnlmucwzaltvz.supabase.co/storage/v1/object/public/email-assets/character/ory_proud.png'
   ```
4. Click **"Deploy"** button

### ✅ Storage Setup Complete!

Your images are now accessible via public URLs that work in emails!

---

## Part 2: Resend Domain Setup (Send to ANY User)

### Why You Need This

- **Without domain**: Resend's test domain (`onboarding@resend.dev`) only sends to **your verified email**
- **With domain**: You can send to **any email address** (all your users!)

### Step 1: Get Your Domain Ready

You need a domain (like `yourdomain.com`). Options:
- **Option A**: Use an existing domain you own
- **Option B**: Buy a domain (Namecheap, GoDaddy, Google Domains - ~$10-15/year)
- **Option C**: Use a subdomain (like `mail.yourdomain.com`)

### Step 2: Add Domain to Resend

1. Go to **Resend Dashboard**: https://resend.com/domains
2. Click **"Add Domain"** button
3. Enter your domain (e.g., `yourdomain.com` or `mail.yourdomain.com`)
4. Click **"Add"**

### Step 3: Get DNS Records from Resend

After adding the domain, Resend will show you **3 DNS records** to add:

1. **SPF Record** (for email authentication)
2. **DKIM Record** (for email security)
3. **DMARC Record** (optional but recommended)

**Copy all 3 records!** They look like:
```
Type: TXT
Name: @
Value: v=spf1 include:resend.dev ~all
```

### Step 4: Add DNS Records to Your Domain

1. Go to your **domain registrar** (where you bought the domain):
   - Namecheap → Domain List → Manage → Advanced DNS
   - GoDaddy → My Products → DNS
   - Google Domains → DNS
   - Cloudflare → DNS → Records

2. **Add each DNS record**:
   - Click **"Add Record"** or **"Add"**
   - Select **Type**: `TXT` (for SPF, DKIM, DMARC)
   - Enter the **Name** from Resend
   - Enter the **Value** from Resend
   - Click **"Save"**

3. **Important**: 
   - Add all 3 records
   - Wait 5-10 minutes for DNS to propagate
   - Don't delete existing records unless Resend says to

### Step 5: Verify Domain in Resend

1. Go back to **Resend Dashboard** → **Domains**
2. You'll see your domain with status: **"Pending Verification"**
3. Click **"Verify"** or wait for auto-verification
4. It can take **5 minutes to 24 hours** (usually 10-30 minutes)
5. Once verified, status changes to **"Verified"** ✅

### Step 6: Update Edge Function to Use Your Domain

1. Go to **Supabase Dashboard** → **Edge Functions** → `send-email`
2. Find this line (around line 4):
   ```typescript
   const FROM_EMAIL = Deno.env.get('FROM_EMAIL') || 'Orion StockSense <onboarding@resend.dev>'
   ```
3. **Replace** with your domain:
   ```typescript
   const FROM_EMAIL = Deno.env.get('FROM_EMAIL') || 'Orion StockSense <noreply@yourdomain.com>'
   ```
   (Replace `yourdomain.com` with your actual domain)
4. Click **"Deploy"**

### Step 7: Test It!

1. Sign up a test user with a **different email** (not your verified one)
2. Check if welcome email arrives
3. Check **Resend Dashboard** → **Emails** → Should show "Delivered"
4. If it works, you're done! 🎉

---

## 🎯 Quick Summary

### Supabase Storage:
- ✅ Bucket name: `email-assets` (public)
- ✅ Folder: `character/`
- ✅ Upload: logo + 4 Ory images
- ✅ Copy URLs → Update edge function

### Resend Domain:
- ✅ Add domain in Resend
- ✅ Add 3 DNS records to your domain
- ✅ Wait for verification
- ✅ Update FROM_EMAIL in edge function

---

## 🐛 Troubleshooting

### "Images not showing in emails"
- ✅ Check bucket is **Public**
- ✅ Test image URL in browser (should load directly)
- ✅ Check URLs in edge function are correct

### "Domain verification failed"
- ✅ Check DNS records are added correctly
- ✅ Wait longer (can take up to 24 hours)
- ✅ Check record names match exactly (case-sensitive)
- ✅ Remove and re-add if needed

### "Emails still not sending to other users"
- ✅ Make sure domain is **Verified** (green checkmark)
- ✅ Check FROM_EMAIL uses your domain (not `@resend.dev`)
- ✅ Test with a different email address

### "DNS records not working"
- ✅ Make sure you're editing DNS at your **domain registrar** (not Resend)
- ✅ Check record **Type** is `TXT`
- ✅ Wait 10-30 minutes for DNS propagation
- ✅ Use a DNS checker tool: https://mxtoolbox.com/

---

## 💡 Pro Tips

1. **Use a subdomain** (like `mail.yourdomain.com`) if you want to keep main domain for website
2. **Test DNS records** before verifying in Resend (use mxtoolbox.com)
3. **Keep test domain** (`onboarding@resend.dev`) for development
4. **Use environment variable** for FROM_EMAIL so you can switch easily:
   ```typescript
   const FROM_EMAIL = Deno.env.get('FROM_EMAIL') || 'Orion StockSense <noreply@yourdomain.com>'
   ```
   Then add `FROM_EMAIL` secret in Supabase with your domain email

---

## ✅ Checklist

### Supabase Storage:
- [ ] Created `email-assets` bucket (public)
- [ ] Uploaded `app_logo.png`
- [ ] Created `character/` folder
- [ ] Uploaded 4 Ory character images
- [ ] Copied all 5 URLs
- [ ] Updated edge function with URLs
- [ ] Deployed edge function

### Resend Domain:
- [ ] Added domain to Resend
- [ ] Copied 3 DNS records
- [ ] Added DNS records to domain registrar
- [ ] Waited for DNS propagation (10-30 min)
- [ ] Verified domain in Resend (green checkmark)
- [ ] Updated FROM_EMAIL in edge function
- [ ] Tested with different email address

---

## 🎉 You're All Set!

Once both are done:
- ✅ Images will show in emails (from Supabase Storage)
- ✅ Emails will send to ANY user (from your verified domain)

**Your email system is now production-ready!** 🚀
