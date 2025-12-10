# 🌐 Resend Domain Setup - Send to ANY Email

## 🔴 The Problem
- Resend's test domain (`onboarding@resend.dev`) only sends to **YOUR account email**
- If you try sending to other emails, Resend blocks it
- You need to **add your own domain** to send to anyone

---

## ✅ Solution: Add Your Domain to Resend

### Option 1: Use Your Existing Domain (Recommended)

If you have a website domain (like `yourwebsite.com`):

#### Step 1: Add Domain in Resend
1. **Go to Resend Dashboard**: https://resend.com/dashboard
2. **Click "Domains"** (left sidebar)
3. **Click "Add Domain"**
4. **Enter your domain**: e.g., `yourwebsite.com` or `orion.app`
5. **Click "Add"**

#### Step 2: Add DNS Records
Resend will show you DNS records to add:

**You need to add these to your domain's DNS settings:**

1. **DKIM Records** (2 records):
   ```
   Name: resend._domainkey
   Type: TXT
   Value: (Resend gives you this)
   ```

2. **SPF Record**:
   ```
   Name: @
   Type: TXT
   Value: v=spf1 include:resend.dev ~all
   ```

3. **Domain Verification**:
   ```
   Name: resend
   Type: TXT
   Value: (Resend gives you this)
   ```

#### Step 3: Where to Add DNS Records
- **Go to your domain registrar** (GoDaddy, Namecheap, Cloudflare, etc.)
- **Find "DNS Settings"** or "DNS Management"
- **Add the records** Resend gives you
- **Wait 5-10 minutes** for DNS to propagate

#### Step 4: Verify Domain
1. **Back in Resend Dashboard** → **Domains**
2. **Click "Verify"** next to your domain
3. **Wait for verification** (can take a few minutes)
4. **Status should change to "Verified"** ✅

#### Step 5: Update Edge Function
Update your Edge Function to use your domain:

```typescript
const FROM_EMAIL = 'notifications@yourdomain.com' // Use YOUR domain
const FROM_NAME = 'Orion Trading App'
```

**Change:**
- Replace `yourdomain.com` with your actual domain
- Use a subdomain like `notifications@`, `noreply@`, or `hello@`

---

### Option 2: Get a Free Domain (If You Don't Have One)

**Free Domain Options:**
1. **Freenom** (free .tk, .ml, .ga domains)
2. **GitHub Pages** (free .github.io subdomain)
3. **Cloudflare Pages** (free subdomains)

**OR use a cheap domain:**
- **Namecheap**: ~$1-2/month
- **GoDaddy**: ~$1-2/month
- **Cloudflare Registrar**: ~$8/year

---

### Option 3: Quick Test Without Domain (Temporary)

For **testing ONLY**, you can:

1. **In Resend Dashboard** → **Settings** → **Email Addresses**
2. **Add test email addresses** you want to send to
3. **Verify those emails** (Resend sends verification email)
4. **Once verified**, you can send to those emails using `onboarding@resend.dev`

**This is just for testing!** For production, you need your own domain.

---

## 🚀 Recommended: Use Your Website Domain

If your website is hosted somewhere, you already have a domain!

**Examples:**
- If your site is `orion-app.com` → use `notifications@orion-app.com`
- If your site is `myapp.vercel.app` → you can't use Vercel's domain, need your own
- If your site is `myapp.netlify.app` → you can't use Netlify's domain, need your own

---

## 📋 Quick Checklist

- [ ] Do you have a domain? (e.g., `yourwebsite.com`)
  - [ ] YES → Add it to Resend and verify
  - [ ] NO → Get a free/cheap domain
- [ ] Add DNS records to your domain
- [ ] Verify domain in Resend
- [ ] Update Edge Function to use your domain
- [ ] Test sending to any email address

---

## 💡 Pro Tip

**If you're using Vercel/Netlify/etc. for hosting:**
- You can still use a custom domain with them
- Just add your domain to Resend (not their subdomain)
- Example: Use `orion.app` with Resend, even if hosting on `myapp.vercel.app`

---

**Once you verify your domain, you can send emails to ANY address!** 🎉

Let me know if you have a domain or need help getting one set up!
