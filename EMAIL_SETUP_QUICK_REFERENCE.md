# 📧 Email Setup - Quick Reference Card

## 🎯 What You Need (Copy This List)

- [ ] Resend account (free)
- [ ] Resend API key (starts with `re_`)
- [ ] Supabase project
- [ ] Supabase Storage bucket for images
- [ ] 5 image files uploaded (logo + 4 Ory characters)

---

## 📋 Quick Checklist

### ✅ Step 1: Resend API Key
1. Go to: https://resend.com
2. Sign up → API Keys → Create API Key
3. Copy the key (starts with `re_`)

### ✅ Step 2: Database Update
1. Supabase → SQL Editor
2. Copy code from: `update_email_logs_schema.sql`
3. Paste → Run

### ✅ Step 3: Edge Function
1. Supabase → Edge Functions → Create `send-email`
2. Copy code from: `supabase/functions/send-email/index.ts`
3. Paste → Deploy

### ✅ Step 4: Secrets
1. Supabase → Edge Functions → Secrets
2. Add: `RESEND_API_KEY` = (your Resend key)
3. Add: `APP_URL` = (your app URL)

### ✅ Step 5: Images
1. Supabase → Storage → Create bucket `email-assets` (Public)
2. Upload: `assets/logo/app_logo.png`
3. Create folder `character` → Upload 4 Ory images
4. Copy URLs → Update edge function with URLs
5. Deploy again

### ✅ Step 6: Test
1. Sign up in your app
2. Check email inbox
3. Check Resend dashboard

---

## 🔗 Important URLs

- **Resend Dashboard**: https://resend.com/emails
- **Supabase Dashboard**: https://app.supabase.com
- **Supabase Edge Functions**: https://app.supabase.com/project/YOUR_PROJECT/functions

---

## 📁 Files You Need

1. `update_email_logs_schema.sql` - Database update
2. `supabase/functions/send-email/index.ts` - Edge function code
3. `assets/logo/app_logo.png` - Logo
4. `assets/character/ory_friendly.png` - Ory friendly
5. `assets/character/ory_concerned.png` - Ory concerned
6. `assets/character/ory_excited.png` - Ory excited
7. `assets/character/ory_proud.png` - Ory proud

---

## ⚡ Quick Copy-Paste Commands

### SQL to Run (Step 2)
```sql
-- Copy from: update_email_logs_schema.sql
```

### Edge Function Code (Step 3)
```
File: supabase/functions/send-email/index.ts
```

### Secrets to Add (Step 4)
```
RESEND_API_KEY = re_xxxxxxxxxxxxx
APP_URL = https://your-app-url.com
```

---

## 🐛 Common Issues

| Problem | Solution |
|---------|----------|
| Email not sending | Check Resend API key in secrets |
| Images not showing | Make Storage bucket Public |
| Edge function error | Check Logs tab for errors |
| Database error | Run SQL script again |

---

## ✅ Success Signs

- ✅ Welcome email received after signup
- ✅ Email has Orion logo at top
- ✅ Email has Ory character image
- ✅ Email looks professional (blue theme)
- ✅ Resend dashboard shows "Delivered"
- ✅ Supabase logs show success

---

**Full guide**: See `EMAIL_SETUP_STEP_BY_STEP.md` for detailed instructions!
