# 📧 Email Not Received? Here's How to Fix It!

## ✅ Step 1: Check Spam Folder

**This is the #1 reason emails don't arrive!**

1. Open your email inbox (Gmail, Outlook, etc.)
2. **Check "Spam" or "Junk" folder**
3. Look for email from `onboarding@resend.dev`
4. If found: **Mark as "Not Spam"** so future emails arrive in inbox

---

## ✅ Step 2: Check Resend Dashboard

1. **Go to Resend Dashboard**: https://resend.com/dashboard
2. **Click "Emails"** (left sidebar)
3. **Check the list** - you should see your test email there
4. **Click on the email** to see:
   - Status: "Delivered", "Bounced", "Pending", etc.
   - If "Bounced": Check the error message
   - If "Pending": Wait a few minutes

---

## ✅ Step 3: Check Edge Function Logs

1. **Go to Supabase Dashboard**
2. **Click "Edge Functions"** → `send-email`
3. **Click "Logs"** tab
4. **Look for errors** (red text)
5. **Common errors:**
   - `Invalid API key` → Check your secret is set correctly
   - `From email not verified` → Need to verify domain (see below)

---

## ✅ Step 4: Verify Email Address in Resend

For testing, you can add your email as a test recipient:

1. **Go to Resend Dashboard**
2. **Click "Settings"** or **"Email Addresses"**
3. **Add your email** as a test recipient
4. **Verify the email** (they'll send a verification email)

OR use Resend's test domain (already verified):
- ✅ `onboarding@resend.dev` is already verified for sending

---

## ✅ Step 5: Check Your Website URL

Make sure you updated the website URL in the Edge Function code:

1. **In Supabase** → **Edge Functions** → `send-email`
2. **Find this line** in the code:
   ```typescript
   href="https://yourwebsite.com"
   ```
3. **Replace** with your actual website URL

---

## ✅ Step 6: Test Again

1. **Go to Supabase** → **Edge Functions** → `send-email` → **Invoke** tab
2. **Use this JSON:**
```json
{
  "type": "welcome",
  "user_id": "test-123",
  "email": "venusianrover@gmail.com",
  "display_name": "Test User"
}
```
3. **Click "Invoke Function"**
4. **Check Resend Dashboard** → **Emails** tab immediately
5. **Check your email** (and spam folder) after 1-2 minutes

---

## 🔍 Common Issues & Fixes

### Issue: "Email sent" but not received
**Solution:**
- ✅ Check spam folder
- ✅ Check Resend Dashboard → Emails tab
- ✅ Wait 2-3 minutes (can be delayed)
- ✅ Try a different email address

### Issue: "From email not verified"
**Solution:**
- ✅ Use `onboarding@resend.dev` (already verified)
- ✅ OR add your own domain in Resend → Domains

### Issue: "Invalid API key"
**Solution:**
- ✅ Check Supabase → Edge Functions → Secrets
- ✅ Make sure `RESEND_API_KEY` is set correctly
- ✅ Redeploy the Edge Function after adding secret

### Issue: Email shows "Bounced" in Resend
**Solution:**
- ✅ Check if email address is valid
- ✅ Some email providers block test emails
- ✅ Try a different email address (Gmail usually works best)

---

## 💡 Pro Tips

1. **Use Gmail for testing** - it's most reliable
2. **Check Resend Dashboard first** - it shows delivery status
3. **Wait 2-3 minutes** - emails aren't instant
4. **Check spam folder** - always check spam first!

---

## 🎯 Quick Checklist

- [ ] Checked spam/junk folder
- [ ] Checked Resend Dashboard → Emails tab
- [ ] Checked Edge Function logs in Supabase
- [ ] Verified email address is correct
- [ ] Tried sending to a Gmail address
- [ ] Waited 2-3 minutes after sending

---

**Still not working?** Check the Resend Dashboard → Emails tab to see the exact status and error message!

