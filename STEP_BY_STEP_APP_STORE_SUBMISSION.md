# 📱 Step-by-Step App Store Submission Guide

**Your Personal Apple ID is PERFECTLY FINE!** Many developers use personal Apple IDs.

---

## ✅ STEP 1: Enroll in Apple Developer Program

### **1.1 Check if You're Already Enrolled**

1. Go to: https://developer.apple.com/account
2. Look at the top of the page:
   - ✅ **If you see "Apple Developer Program"** → You're enrolled! Skip to Step 2
   - ❌ **If you see "Join the Apple Developer Program"** → Continue below

### **1.2 Enroll (If Not Already Enrolled)**

1. Click **"Enroll"** or **"Join the Apple Developer Program"**
2. Select **"Start Your Enrollment"**
3. Choose **"Individual"** (not Company/Organization)
4. Fill out:
   - Your name (can be different from Apple ID)
   - Your address
   - Phone number
5. **Pay $99/year** (credit card)
6. **Wait for approval** (24-48 hours)
   - You'll get an email when approved

**While waiting:** You can prepare screenshots and description (Step 3)

---

## ✅ STEP 2: Create App in App Store Connect

### **2.1 Go to App Store Connect**

1. Go to: https://appstoreconnect.apple.com
2. Sign in with **same Apple ID** you used for developer account
3. Click **"My Apps"** (top left)

### **2.2 Create New App**

1. Click the **"+"** button (top left, next to "My Apps")
2. Select **"New App"**
3. Fill out the form:

   **Platform:** Select **"iOS"**
   
   **Name:** `Orion`
   - This is what users see in App Store
   - Must be unique (if taken, try "Orion - Learn Trading" or "Orion Finance")
   
   **Primary Language:** `English (U.S.)`
   
   **Bundle ID:** Click **"Register a new Bundle ID"** or select existing
   - If registering new:
     - **Description:** "Orion Finance App"
     - **Bundle ID:** `com.akulnehra.orion` (or your preferred ID)
     - Click **"Continue"** → **"Register"**
   - If selecting existing: Choose `com.akulnehra.orion`
   
   **SKU:** `orion-001`
   - This is just an internal identifier (can be anything unique)
   
   **User Access:** Select **"Full Access"**

4. Click **"Create"**

---

## ✅ STEP 3: Fill Out App Information

### **3.1 App Information Tab**

1. In your new app, click **"App Information"** (left sidebar)
2. Fill out:

   **Category:**
   - **Primary:** `Education` (or `Finance`)
   - **Secondary:** `Finance` (or `Education`)
   
   **Privacy Policy URL:** 
   ```
   https://orionfinance.netlify.app/privacy-policy.html
   ```
   
   **Support URL:**
   ```
   mailto:orionai34@gmail.com
   ```
   (Or create a simple support page)
   
   **Marketing URL:** (Optional - leave blank)

### **3.2 Pricing and Availability**

1. Click **"Pricing and Availability"** (left sidebar)
2. Select **"Free"** (or set price if you want)
3. Click **"Save"**

---

## ✅ STEP 4: Upload Screenshots

### **4.1 Prepare Your Screenshots**

You need **6 screenshots** for iPhone (different sizes):
- **6.7" Display (iPhone 14 Pro Max):** 1290 x 2796 pixels
- **6.5" Display (iPhone 11 Pro Max):** 1242 x 2688 pixels
- **5.5" Display (iPhone 8 Plus):** 1242 x 2208 pixels

**Easiest:** Take screenshots on your iPhone, they'll be the right size!

### **4.2 Upload Screenshots**

1. Click **"App Store"** tab (left sidebar)
2. Under **"1.0 Prepare for Submission"**
3. Find **"Screenshots"** section
4. For each iPhone size:
   - Click **"+"** or drag and drop
   - Upload your 6 screenshots
   - **Order matters!** First screenshot is most important

**Tip:** You can upload same screenshots to all sizes (Apple will resize)

---

## ✅ STEP 5: Write App Description

### **5.1 App Description**

1. Still in **"App Store"** tab
2. Scroll to **"Description"** section
3. Paste this (or customize):

```
Learn finance and trading the fun way! Orion is the #1 learning app for high schoolers who want to master the stock market.

🎯 WHAT MAKES ORION SPECIAL:

• Practice Trading Risk-Free
  Trade with virtual money and learn real strategies without risking your savings.

• AI Explains Stocks Simply
  Get instant, easy-to-understand explanations of any stock or market concept.

• Addictive 5-Min Lessons
  Bite-sized, interactive lessons that make learning finance addictive.

• Your Own AI Trading Coach
  Get personalized insights, learn from mistakes, and grow your skills.

• Compete & Win
  Join challenges, share streaks, and climb the leaderboard with friends.

• Your Personal Learning Path
  A clear, guided journey from beginner to confident trader.

🚀 PERFECT FOR:
• High school students learning finance
• Anyone wanting to understand the stock market
• People who learn better by doing
• Future investors and traders

Start your finance journey today - completely free, completely risk-free!
```

### **5.2 Subtitle**

1. Scroll to **"Subtitle"** (below description)
2. Enter: `Learn Finance The Fun Way`

### **5.3 Keywords**

1. Scroll to **"Keywords"**
2. Enter (comma-separated, max 100 characters):
```
finance, trading, stocks, learn, education, paper trading, investing, market, financial education, trading simulator
```

### **5.4 Promotional Text** (Optional)

Leave blank or add:
```
New: Weekly challenges and leaderboard competitions! Learn finance, compete with friends, and master the stock market.
```

### **5.5 Support URL**

1. Scroll to **"Support URL"**
2. Enter: `mailto:orionai34@gmail.com`

### **5.6 Marketing URL** (Optional)

Leave blank

### **5.7 What's New in This Version**

1. Scroll to **"What's New in This Version"**
2. Enter:
```
Welcome to Orion! Learn finance and trading the fun way with:
• Paper trading simulator
• AI-powered stock explanations
• Interactive 5-minute lessons
• Personalized AI trading coach
• Leaderboards and challenges
• Complete learning path
```

---

## ✅ STEP 6: App Privacy

### **6.1 Complete Privacy Questionnaire**

1. Click **"App Privacy"** (left sidebar)
2. Click **"Get Started"** or **"Edit"**
3. Answer questions:

   **Does your app collect data?** → **Yes**
   
   **What types of data?**
   - ✅ **Name** (Account Information)
   - ✅ **Email Address** (Account Information)
   - ✅ **User ID** (Account Information)
   - ✅ **Purchase History** (Financial Info - for paper trading)
   - ✅ **Product Interaction** (Usage Data)
   - ✅ **App Launch** (Usage Data)
   - ✅ **Device ID** (Device ID)
   
   **How is data used?**
   - ✅ **App Functionality**
   - ✅ **Analytics**
   - ✅ **Personalization**
   
   **Is data linked to user?** → **Yes**
   
   **Is data used for tracking?** → **No** (unless you use analytics that track)
   
   **Is data shared with third parties?** → **Yes** (Supabase)
   - Add: **Supabase** (Data Storage Provider)

4. Click **"Save"**

---

## ✅ STEP 7: Age Rating

### **7.1 Set Age Rating**

1. Click **"App Information"** (left sidebar)
2. Scroll to **"Age Rating"**
3. Click **"Edit"**
4. Answer questions:
   - **Does your app contain financial information?** → **Yes**
   - **Does your app allow trading?** → **Yes** (paper trading)
   - **Does your app contain user-generated content?** → **No** (or Yes if leaderboard counts)
   - **Does your app contain social media?** → **No** (or Yes if friends feature counts)
   
5. Rating will be calculated (likely **4+** or **12+**)
6. Click **"Save"**

---

## ✅ STEP 8: Build and Upload Your App

### **8.1 Build Release Version**

1. Open Terminal
2. Navigate to your project:
   ```bash
   cd "/Users/akulnehra/Desktop/Orion Cursor/OrionScreens-master"
   ```
3. Clean and build:
   ```bash
   flutter clean
   flutter pub get
   flutter build ios --release
   ```

### **8.2 Open in Xcode**

1. Open Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
   **Important:** Use `.xcworkspace`, NOT `.xcodeproj`!

### **8.3 Configure Signing**

1. In Xcode, click **"Runner"** (left sidebar, blue icon)
2. Click **"Signing & Capabilities"** tab
3. Under **"Automatically manage signing"**:
   - ✅ Check the box
   - **Team:** Select your Apple Developer account
   - **Bundle Identifier:** Should be `com.akulnehra.orion`

### **8.4 Set Version Number**

1. Still in **"Signing & Capabilities"**
2. **Version:** `1.0.0`
3. **Build:** `1` (or higher if you've uploaded before)

### **8.5 Archive the App**

1. In Xcode menu: **Product** → **Scheme** → **Runner**
2. Select device: **"Any iOS Device"** (top toolbar, next to Run button)
3. **Product** → **Archive**
4. Wait for archive to complete (5-10 minutes)

### **8.6 Upload to App Store Connect**

1. Archive window will open automatically
2. Click **"Distribute App"**
3. Select **"App Store Connect"**
4. Click **"Next"**
5. Select **"Upload"** (not Export)
6. Click **"Next"**
7. Review options:
   - ✅ **Include bitcode** (if available)
   - ✅ **Upload symbols** (if available)
8. Click **"Next"**
9. Review signing:
   - Should be **"Automatically manage signing"**
10. Click **"Upload"**
11. Wait for upload (10-30 minutes)
12. You'll see **"Upload Successful"** when done

---

## ✅ STEP 9: Select Build in App Store Connect

### **9.1 Wait for Processing**

1. Go back to App Store Connect
2. Click your app → **"TestFlight"** tab
3. Wait for build to appear (15-60 minutes)
4. Status will change from **"Processing"** → **"Ready to Submit"**

### **9.2 Select Build for Submission**

1. Go to **"App Store"** tab
2. Scroll to **"Build"** section (under "1.0 Prepare for Submission")
3. Click **"+"** next to **"Build"**
4. Select your build (version 1.0.0, build 1)
5. Click **"Done"**

---

## ✅ STEP 10: Complete App Review Information

### **10.1 Contact Information**

1. Still in **"App Store"** tab
2. Scroll to **"App Review Information"**
3. Fill out:

   **First Name:** Your first name
   
   **Last Name:** Your last name
   
   **Phone Number:** Your phone number
   
   **Email:** `orionai34@gmail.com`
   
   **Notes:** (Optional - leave blank or add):
   ```
   This is an educational app for learning finance and trading. 
   All trading is paper trading (virtual money only).
   No real money transactions occur in this app.
   ```

### **10.2 Demo Account** (If Required)

If your app requires login:
- **Username:** (test account email)
- **Password:** (test account password)
- **Notes:** "Test account for review purposes"

---

## ✅ STEP 11: Export Compliance

### **11.1 Answer Export Questions**

1. Scroll to **"Export Compliance"**
2. Answer:

   **Does your app use encryption?** → **No**
   - (Unless you're using advanced encryption, which you're not)
   
   **Does your app use standard encryption?** → **No**

3. Click **"Save"**

---

## ✅ STEP 12: Submit for Review!

### **12.1 Final Review**

1. Scroll to top of **"App Store"** tab
2. Review everything:
   - ✅ Screenshots uploaded
   - ✅ Description filled out
   - ✅ Build selected
   - ✅ Privacy Policy URL added
   - ✅ Support URL added
   - ✅ Age rating set
   - ✅ App Privacy completed

### **12.2 Submit**

1. Click **"Add for Review"** (top right, blue button)
2. Confirm submission
3. Status changes to **"Waiting for Review"**

---

## ✅ STEP 13: Wait for Review

### **13.1 Review Timeline**

- **Initial Review:** 24-48 hours
- **Status Updates:** Check App Store Connect daily
- **You'll get email** when status changes

### **13.2 Possible Outcomes**

**✅ Approved:**
- Status: **"Ready for Sale"**
- App goes live automatically (or on your selected date)

**❌ Rejected:**
- Status: **"Rejected"**
- You'll get email with reasons
- Fix issues and resubmit

**⚠️ In Review:**
- Status: **"In Review"**
- Apple is testing your app
- Usually takes 1-2 days

---

## 📋 Quick Checklist

Before submitting, make sure:

- [ ] Apple Developer account enrolled ($99 paid)
- [ ] App created in App Store Connect
- [ ] Bundle ID: `com.akulnehra.orion`
- [ ] 6 screenshots uploaded
- [ ] Description written
- [ ] Privacy Policy URL: `https://orionfinance.netlify.app/privacy-policy.html`
- [ ] Terms URL: `https://orionfinance.netlify.app/terms-of-service.html`
- [ ] Support URL: `mailto:orionai34@gmail.com`
- [ ] App Privacy completed
- [ ] Age rating set
- [ ] Build uploaded and selected
- [ ] App Review Information filled out
- [ ] Export Compliance answered
- [ ] Ready to submit!

---

## 🆘 Common Issues & Fixes

### **Issue: "Bundle ID not found"**
**Fix:** Make sure Bundle ID matches in:
- Xcode (Signing & Capabilities)
- App Store Connect (App Information)

### **Issue: "Build not showing up"**
**Fix:** 
- Wait 30-60 minutes for processing
- Check TestFlight tab for build status
- Make sure build version matches

### **Issue: "Signing failed"**
**Fix:**
- Make sure you selected your team in Xcode
- Check Bundle ID matches
- Try "Automatically manage signing"

### **Issue: "Upload failed"**
**Fix:**
- Check internet connection
- Try uploading again
- Make sure Xcode is up to date

---

## 🎯 You're Ready!

Follow these steps one by one, and you'll have your app submitted in no time!

**Need help with any step?** Just ask! 🚀

