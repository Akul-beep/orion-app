# 🦉 Orion Character Design Guide

## Character Overview

**Name**: **Orion** (matches the app name, references the constellation)

**Purpose**: The app's mascot character, similar to Duolingo's Duo. Orion helps users stay engaged through friendly (and sometimes concerned) notifications.

## Design Requirements

### Visual Style
- **Color Scheme**: Blue tones matching the app's UI
  - Primary: `#1E3A8A` (Deep professional blue)
  - Accent: `#3B82F6` (Lighter blue)
  - Should feel professional yet approachable

### Character Personality
- **Friendly**: Normal state - encouraging and supportive
- **Concerned**: When streak is at risk (like Duo's "angry" but more professional/gentle)
- **Excited**: When user achieves something (level up, badge unlock)
- **Proud**: When user maintains consistent progress

### Design Specifications

**For AI Image Generation (Midjourney/DALL-E/etc.)**:

```
A friendly, professional blue mascot character for a financial trading app.
Design: Cute but professional, blue color scheme matching #1E3A8A and #3B82F6.
Style: Modern, approachable, similar to Duolingo's Duo but with a financial/trading theme.
Expression: Can show friendly, encouraging, and "concerned" (not angry, but worried) expressions.
Should have a professional yet playful appearance that matches a trading/learning app.
Character should be simple, recognizable, and work well as a small icon/avatar.
```

### Character Traits
- **Professional but Playful**: Should feel trustworthy (financial app) but also fun (gamification)
- **Expressive**: Needs to convey different emotions (friendly, concerned, excited, proud)
- **Simple**: Should work well at small sizes (notification icons, avatars)
- **Memorable**: Should be instantly recognizable as "Orion"

### Expression Variations Needed

1. **Friendly/Neutral** (default)
   - Warm smile
   - Open, welcoming expression
   - Used for normal reminders

2. **Concerned/Worried** (streak at risk)
   - Slightly worried expression
   - Not angry, but clearly concerned
   - Used when user hasn't completed goals

3. **Excited** (achievements)
   - Happy, celebratory expression
   - Used for level ups, badge unlocks

4. **Proud** (milestones)
   - Confident, proud expression
   - Used for streak milestones

## Character Name

**Selected**: **Orion**
- Matches the app name
- References the constellation (fits space/financial theme)
- Easy to remember
- Professional yet approachable

**Alternative Names** (if you prefer):
- **Orry** (playful nickname)
- **Apex** (trading term)
- **Nova** (bright star)
- **Orbit** (space-themed)

## Implementation

The character is already integrated into the notification system:
- All notifications use Orion's personality
- Messages are personalized with Orion's voice
- Character moods adapt to context (friendly → concerned when streak at risk)

## Image Requirements

### Sizes Needed
1. **Notification Icon**: 256x256px (for push notifications)
2. **Avatar**: 128x128px (for in-app use)
3. **Large**: 512x512px (for splash screens, marketing)

### Formats
- PNG with transparent background
- SVG (optional, for scalability)

### File Naming
- `orion_friendly.png` (default expression)
- `orion_concerned.png` (streak at risk)
- `orion_excited.png` (achievements)
- `orion_proud.png` (milestones)

## Example Prompts for AI Generation

### Midjourney/DALL-E Prompt:
```
A friendly, professional blue mascot character named Orion for a financial trading app. 
Cute but professional design, blue color scheme (#1E3A8A, #3B82F6). 
Modern, approachable style similar to Duolingo's Duo but with a financial/trading theme. 
Simple, recognizable character that works well as a small icon. 
Professional yet playful appearance. 
Clean, modern illustration style. 
Transparent background.
```

### Character Description:
- **Type**: Mascot character (animal or abstract creature)
- **Colors**: Blue tones (#1E3A8A primary, #3B82F6 accent)
- **Style**: Modern, clean, professional but friendly
- **Mood**: Approachable, trustworthy, encouraging
- **Complexity**: Simple enough to work at small sizes

## Integration Notes

Once you have the character images:
1. Add them to `assets/characters/` folder
2. Update `push_notification_service.dart` to use character images in notifications
3. The system is already set up to use them - just uncomment the `largeIcon` code

## Current Status

✅ Character personality system implemented
✅ Notification messages use Orion's voice
✅ Character moods integrated (friendly, concerned, excited, proud)
⏳ Waiting for character images to complete visual integration

---

**Next Step**: Generate character images using the prompts above, then add them to the app!

