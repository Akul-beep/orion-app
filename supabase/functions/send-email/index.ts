import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')
const FROM_EMAIL = Deno.env.get('FROM_EMAIL') || 'Orion StockSense <onboarding@resend.dev>'
const APP_URL = Deno.env.get('APP_URL') || 'https://your-app-url.com'

// Image URLs - Update these with your Supabase Storage URLs
// Step 1: Create bucket 'email-assets' in Supabase Storage (make it PUBLIC)
// Step 2: Upload logo to bucket root: app_logo.png
// Step 3: Create folder 'character' and upload 4 Ory images
// Step 4: Copy URLs from Supabase Storage and paste below
// Format: https://YOUR_PROJECT.supabase.co/storage/v1/object/public/email-assets/...

// Replace these with your actual Supabase Storage URLs:
const ORION_LOGO_URL = Deno.env.get('ORION_LOGO_URL') || 'https://lpchovurnlmucwzaltvz.supabase.co/storage/v1/object/public/email-assets/app_logo.png'
const ORY_FRIENDLY_URL = Deno.env.get('ORY_FRIENDLY_URL') || 'https://lpchovurnlmucwzaltvz.supabase.co/storage/v1/object/public/email-assets/character/ory_friendly.png'
const ORY_CONCERNED_URL = Deno.env.get('ORY_CONCERNED_URL') || 'https://lpchovurnlmucwzaltvz.supabase.co/storage/v1/object/public/email-assets/character/ory_concerned.png'
const ORY_EXCITED_URL = Deno.env.get('ORY_EXCITED_URL') || 'https://lpchovurnlmucwzaltvz.supabase.co/storage/v1/object/public/email-assets/character/ory_excited.png'
const ORY_PROUD_URL = Deno.env.get('ORY_PROUD_URL') || 'https://lpchovurnlmucwzaltvz.supabase.co/storage/v1/object/public/email-assets/character/ory_proud.png'

serve(async (req) => {
  try {
    const { 
      type, 
      user_id, 
      email, 
      display_name, 
      days_since_last_active, 
      day_number,
      portfolio_value,
      portfolio_change,
      portfolio_change_percent,
      leaderboard_rank,
      leaderboard_change,
      weekly_stats,
      streak,
      previous_streak,
      level,
      previous_level,
      xp,
      achievement_name,
      achievement_description,
      market_news_title,
      market_news_summary,
      hours_since_activity
    } = await req.json()

    if (!email) {
      throw new Error('Email is required')
    }

    let subject = ''
    let html = ''

    switch (type) {
      case 'welcome':
        subject = `Welcome to Orion StockSense, ${display_name || 'there'}! 🚀`
        html = generateWelcomeEmail(display_name || 'there')
        break

      case 'retention':
        const mood = days_since_last_active >= 14 ? 'concerned' : 'friendly'
        subject = days_since_last_active >= 14 
          ? `We miss you! Your portfolio needs you 🦉`
          : `Hey ${display_name || 'there'}, it's been a while! 📈`
        html = generateRetentionEmail(display_name || 'there', days_since_last_active, mood, portfolio_value, streak)
        break

      case 'portfolio_update':
        subject = `📊 Your Portfolio Update: ${portfolio_change_percent >= 0 ? '📈' : '📉'} ${portfolio_change_percent >= 0 ? '+' : ''}${portfolio_change_percent?.toFixed(2)}%`
        html = generatePortfolioUpdateEmail(display_name || 'there', portfolio_value, portfolio_change, portfolio_change_percent, streak)
        break

      case 'leaderboard_update':
        const rankEmoji = leaderboard_rank <= 3 ? '🏆' : leaderboard_rank <= 10 ? '🥇' : '📊'
        subject = `${rankEmoji} You're #${leaderboard_rank} on the Leaderboard!`
        html = generateLeaderboardUpdateEmail(display_name || 'there', leaderboard_rank, leaderboard_change, portfolio_value, level, streak)
        break

      case 'weekly_summary':
        subject = `📈 Your Weekly Trading Summary`
        html = generateWeeklySummaryEmail(display_name || 'there', weekly_stats, portfolio_value, streak, level)
        break

      case 'onboarding':
        subject = `Day ${day_number}: ${getOnboardingSubject(day_number)}`
        html = generateOnboardingEmail(display_name || 'there', day_number)
        break

      case 'feedback_request':
        subject = 'We'd love your feedback! 💬'
        html = generateFeedbackRequestEmail(display_name || 'there')
        break

      case 'streak_at_risk':
        subject = `🚨 Your ${streak || 0}-day streak is at risk!`
        html = generateStreakAtRiskEmail(display_name || 'there', streak || 0, hours_since_activity)
        break

      case 'streak_lost':
        subject = `😢 Your ${previous_streak || 0}-day streak was broken...`
        html = generateStreakLostEmail(display_name || 'there', previous_streak || 0)
        break

      case 'streak_milestone':
        subject = `🔥 Amazing! ${streak || 0}-day streak!`
        html = generateStreakMilestoneEmail(display_name || 'there', streak || 0)
        break

      case 'achievement_unlocked':
        subject = `🎉 Achievement Unlocked: ${achievement_name || 'New Badge'}!`
        html = generateAchievementEmail(display_name || 'there', achievement_name, achievement_description)
        break

      case 'level_up':
        subject = `⭐ Level Up! You're now Level ${level || 0}!`
        html = generateLevelUpEmail(display_name || 'there', level || 0, previous_level || 0, xp)
        break

      case 'market_update':
        subject = `📈 Market Update: ${market_news_title || 'Market News'}`
        html = generateMarketUpdateEmail(display_name || 'there', market_news_title, market_news_summary)
        break

      case 'daily_reminder':
        subject = `📊 Don't forget to check your portfolio today!`
        html = generateDailyReminderEmail(display_name || 'there', streak, portfolio_value)
        break

      case 'friend_activity':
        subject = `👥 Your friends are active!`
        html = generateFriendActivityEmail(display_name || 'there')
        break

      default:
        throw new Error(`Unknown email type: ${type}`)
    }

    // Send email via Resend
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: FROM_EMAIL,
        to: email,
        subject: subject,
        html: html,
      }),
    })

    if (!response.ok) {
      const error = await response.text()
      throw new Error(`Resend API error: ${response.status} - ${error}`)
    }

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    console.error('Email error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    )
  }
})

// Email Template Generator Functions

function generateWelcomeEmail(displayName: string): string {
  return `
    ${getEmailHeader('excited')}
    <div style="${getContainerStyle()}">
      <div style="${getContentStyle()}">
        <h1 style="${getHeadingStyle()}">Welcome to Orion StockSense! 🚀</h1>
        <p style="${getParagraphStyle()}">Hi ${displayName},</p>
        <p style="${getParagraphStyle()}">
          I'm Ory, your trading companion! I'm so excited you're here. 🦉
        </p>
        <p style="${getParagraphStyle()}">
          Orion StockSense is your personal trading playground where you can learn, practice, and compete—all without risking real money. 
          Start with paper trading, level up your skills, and climb the leaderboard!
        </p>
        <div style="${getCtaContainerStyle()}">
          <a href="${APP_URL}" style="${getCtaButtonStyle()}">Start Trading Now →</a>
        </div>
        <div style="${getFeatureBoxStyle()}">
          <h3 style="${getSubheadingStyle()}">What you can do:</h3>
          <ul style="${getListStyle()}">
            <li>📊 Paper trade with virtual money</li>
            <li>📚 Learn with interactive lessons</li>
            <li>🏆 Compete on the leaderboard</li>
            <li>🔥 Build your trading streak</li>
            <li>🎯 Earn badges and level up</li>
          </ul>
        </div>
        <p style="${getParagraphStyle()}">
          Ready to start? Let's make your first trade together!
        </p>
        <p style="${getParagraphStyle()}">
          Best,<br>
          <strong>Ory</strong> 🦉<br>
          Your Trading Companion
        </p>
      </div>
    </div>
    ${getEmailFooter()}
  `
}

function generateRetentionEmail(displayName: string, daysSince: number, mood: string, portfolioValue?: number, streak?: number): string {
  const oryImage = mood === 'concerned' ? ORY_CONCERNED_URL : ORY_FRIENDLY_URL
  const isUrgent = daysSince >= 14
  
  let message = ''
  let ctaText = ''
  
  if (isUrgent) {
    message = `
      <p style="${getParagraphStyle()}">
        It's been <strong>${daysSince} days</strong> since you last checked in, and I'm getting worried! 😰
      </p>
      <p style="${getParagraphStyle()}">
        Your portfolio is waiting for you, and I don't want you to miss out on potential gains. 
        ${portfolioValue ? `Your portfolio is currently worth <strong>$${portfolioValue.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</strong>.` : ''}
      </p>
      <p style="${getParagraphStyle()}">
        ${streak ? `You had a ${streak}-day streak going—don't let it break! 🔥` : 'Let\'s get you back on track!'}
      </p>
    `
    ctaText = 'Save My Portfolio! 🚨'
  } else {
    message = `
      <p style="${getParagraphStyle()}">
        Hey ${displayName}! 👋 It's been ${daysSince} days since we last saw you.
      </p>
      <p style="${getParagraphStyle()}">
        I've been keeping an eye on your portfolio, and there's been some activity you might want to check out! 
        ${portfolioValue ? `Your portfolio is currently worth <strong>$${portfolioValue.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</strong>.` : ''}
      </p>
      <p style="${getParagraphStyle()}">
        ${streak ? `You're on a ${streak}-day streak—keep it going! 🔥` : 'Come back and see what you\'ve been missing!'}
      </p>
    `
    ctaText = 'Check My Portfolio 📊'
  }

  return `
    ${getEmailHeader(mood)}
    <div style="${getContainerStyle()}">
      <div style="${getContentStyle()}">
        <div style="text-align: center; margin-bottom: 30px;">
          <img src="${oryImage}" alt="Ory" style="width: 120px; height: 120px; border-radius: 50%;" />
        </div>
        <h1 style="${getHeadingStyle()}">${isUrgent ? 'We Miss You! 😰' : 'Hey, It\'s Been A While!'}</h1>
        ${message}
        <div style="${getCtaContainerStyle()}">
          <a href="${APP_URL}" style="${getCtaButtonStyle(isUrgent ? '#DC2626' : undefined)}">${ctaText}</a>
        </div>
        <div style="${getFeatureBoxStyle()}">
          <h3 style="${getSubheadingStyle()}">What you're missing:</h3>
          <ul style="${getListStyle()}">
            <li>📈 Real-time portfolio updates</li>
            <li>🏆 Your position on the leaderboard</li>
            <li>📚 New learning modules</li>
            <li>🎯 Daily challenges and rewards</li>
          </ul>
        </div>
        <p style="${getParagraphStyle()}">
          See you soon!<br>
          <strong>Ory</strong> 🦉
        </p>
      </div>
    </div>
    ${getEmailFooter()}
  `
}

function generatePortfolioUpdateEmail(displayName: string, portfolioValue: number, change?: number, changePercent?: number, streak?: number): string {
  const isPositive = (changePercent ?? 0) >= 0
  const oryImage = isPositive ? ORY_EXCITED_URL : ORY_CONCERNED_URL
  const changeColor = isPositive ? '#10B981' : '#EF4444'
  const changeSymbol = isPositive ? '+' : ''

  return `
    ${getEmailHeader(isPositive ? 'excited' : 'concerned')}
    <div style="${getContainerStyle()}">
      <div style="${getContentStyle()}">
        <div style="text-align: center; margin-bottom: 30px;">
          <img src="${oryImage}" alt="Ory" style="width: 120px; height: 120px; border-radius: 50%;" />
        </div>
        <h1 style="${getHeadingStyle()}">Your Portfolio Update 📊</h1>
        <p style="${getParagraphStyle()}">Hi ${displayName},</p>
        <p style="${getParagraphStyle()}">
          ${isPositive ? 'Great news! 🎉' : 'Here\'s your portfolio update:'}
        </p>
        <div style="${getStatsBoxStyle()}">
          <div style="text-align: center; padding: 30px; background: linear-gradient(135deg, #1E3A8A 0%, #3B82F6 100%); border-radius: 12px; color: white; margin: 20px 0;">
            <div style="font-size: 14px; opacity: 0.9; margin-bottom: 8px;">Portfolio Value</div>
            <div style="font-size: 36px; font-weight: bold; margin-bottom: 8px;">
              $${portfolioValue.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </div>
            ${changePercent !== undefined ? `
              <div style="font-size: 18px; font-weight: 600; color: ${changeColor};">
                ${changeSymbol}${changePercent.toFixed(2)}% 
                ${change !== undefined ? `(${changeSymbol}$${Math.abs(change).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })})` : ''}
              </div>
            ` : ''}
          </div>
        </div>
        ${streak ? `
          <div style="${getFeatureBoxStyle()}">
            <p style="margin: 0; font-size: 16px; color: #1E3A8A;">
              🔥 <strong>${streak}-day streak!</strong> Keep it going!
            </p>
          </div>
        ` : ''}
        <div style="${getCtaContainerStyle()}">
          <a href="${APP_URL}" style="${getCtaButtonStyle()}">View Full Portfolio →</a>
        </div>
        <p style="${getParagraphStyle()}">
          ${isPositive ? 'Keep up the great work!' : 'Don\'t worry, markets go up and down. Keep learning!'}
        </p>
        <p style="${getParagraphStyle()}">
          Best,<br>
          <strong>Ory</strong> 🦉
        </p>
      </div>
    </div>
    ${getEmailFooter()}
  `
}

function generateLeaderboardUpdateEmail(displayName: string, rank: number, rankChange?: number, portfolioValue?: number, level?: number, streak?: number): string {
  const isTopRank = rank <= 10
  const oryImage = isTopRank ? ORY_EXCITED_URL : ORY_FRIENDLY_URL
  const rankEmoji = rank === 1 ? '🥇' : rank === 2 ? '🥈' : rank === 3 ? '🥉' : rank <= 10 ? '🏆' : '📊'
  const rankChangeText = rankChange ? (rankChange > 0 ? `⬆️ Moved up ${rankChange} spots!` : rankChange < 0 ? `⬇️ Dropped ${Math.abs(rankChange)} spots` : 'No change') : ''

  return `
    ${getEmailHeader(isTopRank ? 'excited' : 'friendly')}
    <div style="${getContainerStyle()}">
      <div style="${getContentStyle()}">
        <div style="text-align: center; margin-bottom: 30px;">
          <img src="${oryImage}" alt="Ory" style="width: 120px; height: 120px; border-radius: 50%;" />
        </div>
        <h1 style="${getHeadingStyle()}">Leaderboard Update ${rankEmoji}</h1>
        <p style="${getParagraphStyle()}">Hi ${displayName},</p>
        <p style="${getParagraphStyle()}">
          ${isTopRank ? 'Congratulations! You\'re in the top 10! 🎉' : 'Here\'s where you stand:'}
        </p>
        <div style="${getStatsBoxStyle()}">
          <div style="text-align: center; padding: 30px; background: linear-gradient(135deg, #1E3A8A 0%, #3B82F6 100%); border-radius: 12px; color: white; margin: 20px 0;">
            <div style="font-size: 14px; opacity: 0.9; margin-bottom: 8px;">Your Rank</div>
            <div style="font-size: 48px; font-weight: bold; margin-bottom: 8px;">
              #${rank}
            </div>
            ${rankChangeText ? `<div style="font-size: 16px; opacity: 0.9;">${rankChangeText}</div>` : ''}
          </div>
        </div>
        <div style="${getFeatureBoxStyle()}">
          <h3 style="${getSubheadingStyle()}">Your Stats:</h3>
          <ul style="${getListStyle()}">
            ${portfolioValue ? `<li>💰 Portfolio: $${portfolioValue.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</li>` : ''}
            ${level ? `<li>⭐ Level: ${level}</li>` : ''}
            ${streak ? `<li>🔥 Streak: ${streak} days</li>` : ''}
          </ul>
        </div>
        <div style="${getCtaContainerStyle()}">
          <a href="${APP_URL}" style="${getCtaButtonStyle()}">View Full Leaderboard →</a>
        </div>
        <p style="${getParagraphStyle()}">
          ${isTopRank ? 'Keep pushing to stay on top!' : 'Keep trading to climb higher!'}
        </p>
        <p style="${getParagraphStyle()}">
          Best,<br>
          <strong>Ory</strong> 🦉
        </p>
      </div>
    </div>
    ${getEmailFooter()}
  `
}

function generateWeeklySummaryEmail(displayName: string, stats: any, portfolioValue?: number, streak?: number, level?: number): string {
  const oryImage = ORY_PROUD_URL
  
  return `
    ${getEmailHeader('proud')}
    <div style="${getContainerStyle()}">
      <div style="${getContentStyle()}">
        <div style="text-align: center; margin-bottom: 30px;">
          <img src="${oryImage}" alt="Ory" style="width: 120px; height: 120px; border-radius: 50%;" />
        </div>
        <h1 style="${getHeadingStyle()}">Your Weekly Trading Summary 📈</h1>
        <p style="${getParagraphStyle()}">Hi ${displayName},</p>
        <p style="${getParagraphStyle()}">
          Here's what you accomplished this week! 🎉
        </p>
        <div style="${getStatsBoxStyle()}">
          ${portfolioValue ? `
            <div style="background: #F3F4F6; padding: 20px; border-radius: 8px; margin: 10px 0;">
              <div style="font-size: 14px; color: #6B7280; margin-bottom: 4px;">Portfolio Value</div>
              <div style="font-size: 24px; font-weight: bold; color: #1E3A8A;">
                $${portfolioValue.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
              </div>
            </div>
          ` : ''}
          ${stats?.trades ? `
            <div style="background: #F3F4F6; padding: 20px; border-radius: 8px; margin: 10px 0;">
              <div style="font-size: 14px; color: #6B7280; margin-bottom: 4px;">Trades This Week</div>
              <div style="font-size: 24px; font-weight: bold; color: #1E3A8A;">${stats.trades}</div>
            </div>
          ` : ''}
          ${streak ? `
            <div style="background: #F3F4F6; padding: 20px; border-radius: 8px; margin: 10px 0;">
              <div style="font-size: 14px; color: #6B7280; margin-bottom: 4px;">Current Streak</div>
              <div style="font-size: 24px; font-weight: bold; color: #1E3A8A;">${streak} days 🔥</div>
            </div>
          ` : ''}
          ${level ? `
            <div style="background: #F3F4F6; padding: 20px; border-radius: 8px; margin: 10px 0;">
              <div style="font-size: 14px; color: #6B7280; margin-bottom: 4px;">Level</div>
              <div style="font-size: 24px; font-weight: bold; color: #1E3A8A;">${level}</div>
            </div>
          ` : ''}
        </div>
        <div style="${getCtaContainerStyle()}">
          <a href="${APP_URL}" style="${getCtaButtonStyle()}">Continue Trading →</a>
        </div>
        <p style="${getParagraphStyle()}">
          Great work this week! Keep it up! 🚀
        </p>
        <p style="${getParagraphStyle()}">
          Best,<br>
          <strong>Ory</strong> 🦉
        </p>
      </div>
    </div>
    ${getEmailFooter()}
  `
}

function generateOnboardingEmail(displayName: string, dayNumber: number): string {
  const content = getOnboardingContent(dayNumber)
  const oryImage = ORY_FRIENDLY_URL

  return `
    ${getEmailHeader('friendly')}
    <div style="${getContainerStyle()}">
      <div style="${getContentStyle()}">
        <div style="text-align: center; margin-bottom: 30px;">
          <img src="${oryImage}" alt="Ory" style="width: 120px; height: 120px; border-radius: 50%;" />
        </div>
        <h1 style="${getHeadingStyle()}">Day ${dayNumber} of Your Journey 🚀</h1>
        <p style="${getParagraphStyle()}">Hi ${displayName},</p>
        <p style="${getParagraphStyle()}">
          ${content}
        </p>
        <div style="${getCtaContainerStyle()}">
          <a href="${APP_URL}" style="${getCtaButtonStyle()}">Get Started →</a>
        </div>
        <p style="${getParagraphStyle()}">
          Let's keep learning together!<br>
          <strong>Ory</strong> 🦉
        </p>
      </div>
    </div>
    ${getEmailFooter()}
  `
}

function generateFeedbackRequestEmail(displayName: string): string {
  return `
    ${getEmailHeader('friendly')}
    <div style="${getContainerStyle()}">
      <div style="${getContentStyle()}">
        <h1 style="${getHeadingStyle()}">We'd Love Your Feedback! 💬</h1>
        <p style="${getParagraphStyle()}">Hi ${displayName},</p>
        <p style="${getParagraphStyle()}">
          Your opinion matters! We're constantly working to make Orion StockSense better, 
          and we'd love to hear what you think.
        </p>
        <div style="${getCtaContainerStyle()}">
          <a href="${APP_URL}" style="${getCtaButtonStyle()}">Share Your Feedback →</a>
        </div>
        <p style="${getParagraphStyle()}">
          Thank you for being part of our community!<br>
          <strong>The Orion Team</strong> 🦉
        </p>
      </div>
    </div>
    ${getEmailFooter()}
  `
}

function generateStreakAtRiskEmail(displayName: string, streak: number, hoursSince?: number): string {
  const hoursText = hoursSince ? `You haven't been active for ${hoursSince} hours. ` : ''
  
  return `
    ${getEmailHeader('concerned')}
    <div style="${getContainerStyle()}">
      <div style="${getContentStyle()}">
        <div style="text-align: center; margin-bottom: 30px;">
          <img src="${ORY_CONCERNED_URL}" alt="Ory" style="width: 120px; height: 120px; border-radius: 50%;" />
        </div>
        <h1 style="${getHeadingStyle()}">🚨 Your Streak is at Risk!</h1>
        <p style="${getParagraphStyle()}">Hi ${displayName},</p>
        <p style="${getParagraphStyle()}">
          ${hoursText}Your <strong>${streak}-day streak</strong> is about to break! 😰
        </p>
        <p style="${getParagraphStyle()}">
          Don't let all that hard work go to waste! Just a quick check-in today will save your streak.
        </p>
        <div style="${getStatsBoxStyle()}">
          <div style="text-align: center; padding: 30px; background: linear-gradient(135deg, #DC2626 0%, #EF4444 100%); border-radius: 12px; color: white; margin: 20px 0;">
            <div style="font-size: 14px; opacity: 0.9; margin-bottom: 8px;">Current Streak</div>
            <div style="font-size: 48px; font-weight: bold; margin-bottom: 8px;">
              ${streak} 🔥
            </div>
            <div style="font-size: 16px; opacity: 0.9;">Don't let it break!</div>
          </div>
        </div>
        <div style="${getCtaContainerStyle()}">
          <a href="${APP_URL}" style="${getCtaButtonStyle('#DC2626')}">Save My Streak! 🚨</a>
        </div>
        <p style="${getParagraphStyle()}">
          You've come so far! Just one more day to keep it going! 💪
        </p>
        <p style="${getParagraphStyle()}">
          <strong>Ory</strong> 🦉
        </p>
      </div>
    </div>
    ${getEmailFooter()}
  `
}

function generateStreakLostEmail(displayName: string, previousStreak: number): string {
  return `
    ${getEmailHeader('concerned')}
    <div style="${getContainerStyle()}">
      <div style="${getContentStyle()}">
        <div style="text-align: center; margin-bottom: 30px;">
          <img src="${ORY_CONCERNED_URL}" alt="Ory" style="width: 120px; height: 120px; border-radius: 50%;" />
        </div>
        <h1 style="${getHeadingStyle()}">Your Streak Was Broken... 😢</h1>
        <p style="${getParagraphStyle()}">Hi ${displayName},</p>
        <p style="${getParagraphStyle()}">
          I'm sorry to tell you this, but your <strong>${previousStreak}-day streak</strong> was broken.
        </p>
        <p style="${getParagraphStyle()}">
          But don't worry! Every great trader starts fresh. Let's build an even longer streak together!
        </p>
        <div style="${getFeatureBoxStyle()}">
          <h3 style="${getSubheadingStyle()}">Ready to start again?</h3>
          <ul style="${getListStyle()}">
            <li>🔥 Start a new streak today</li>
            <li>📊 Check your portfolio</li>
            <li>📚 Complete a lesson</li>
            <li>💼 Make a trade</li>
          </ul>
        </div>
        <div style="${getCtaContainerStyle()}">
          <a href="${APP_URL}" style="${getCtaButtonStyle()}">Start New Streak →</a>
        </div>
        <p style="${getParagraphStyle()}">
          You've got this! Let's make it even better this time! 💪
        </p>
        <p style="${getParagraphStyle()}">
          <strong>Ory</strong> 🦉
        </p>
      </div>
    </div>
    ${getEmailFooter()}
  `
}

function generateStreakMilestoneEmail(displayName: string, streak: number): string {
  const milestoneText = streak === 7 ? 'One week!' : 
                        streak === 14 ? 'Two weeks!' :
                        streak === 30 ? 'One month!' :
                        streak === 100 ? '100 days! Incredible!' : 
                        `${streak} days!`
  
  return `
    ${getEmailHeader('proud')}
    <div style="${getContainerStyle()}">
      <div style="${getContentStyle()}">
        <div style="text-align: center; margin-bottom: 30px;">
          <img src="${ORY_PROUD_URL}" alt="Ory" style="width: 120px; height: 120px; border-radius: 50%;" />
        </div>
        <h1 style="${getHeadingStyle()}">🔥 Amazing Streak Milestone! 🔥</h1>
        <p style="${getParagraphStyle()}">Hi ${displayName},</p>
        <p style="${getParagraphStyle()}">
          Congratulations! You've reached a <strong>${streak}-day streak</strong>! ${milestoneText} 🎉
        </p>
        <div style="${getStatsBoxStyle()}">
          <div style="text-align: center; padding: 30px; background: linear-gradient(135deg, #F59E0B 0%, #FBBF24 100%); border-radius: 12px; color: white; margin: 20px 0;">
            <div style="font-size: 14px; opacity: 0.9; margin-bottom: 8px;">Streak Milestone</div>
            <div style="font-size: 48px; font-weight: bold; margin-bottom: 8px;">
              ${streak} 🔥
            </div>
            <div style="font-size: 16px; opacity: 0.9;">Keep it going!</div>
          </div>
        </div>
        <p style="${getParagraphStyle()}">
          Your consistency is paying off! Keep up the amazing work! 🚀
        </p>
        <div style="${getCtaContainerStyle()}">
          <a href="${APP_URL}" style="${getCtaButtonStyle()}">Continue Your Streak →</a>
        </div>
        <p style="${getParagraphStyle()}">
          Proud of you!<br>
          <strong>Ory</strong> 🦉
        </p>
      </div>
    </div>
    ${getEmailFooter()}
  `
}

function generateAchievementEmail(displayName: string, achievementName?: string, achievementDescription?: string): string {
  return `
    ${getEmailHeader('excited')}
    <div style="${getContainerStyle()}">
      <div style="${getContentStyle()}">
        <div style="text-align: center; margin-bottom: 30px;">
          <img src="${ORY_EXCITED_URL}" alt="Ory" style="width: 120px; height: 120px; border-radius: 50%;" />
        </div>
        <h1 style="${getHeadingStyle()}">🎉 Achievement Unlocked! 🎉</h1>
        <p style="${getParagraphStyle()}">Hi ${displayName},</p>
        <p style="${getParagraphStyle()}">
          Amazing news! You just unlocked a new achievement! 🏆
        </p>
        <div style="${getStatsBoxStyle()}">
          <div style="text-align: center; padding: 30px; background: linear-gradient(135deg, #8B5CF6 0%, #A78BFA 100%); border-radius: 12px; color: white; margin: 20px 0;">
            <div style="font-size: 14px; opacity: 0.9; margin-bottom: 8px;">New Achievement</div>
            <div style="font-size: 32px; font-weight: bold; margin-bottom: 8px;">
              ${achievementName || '🏆 New Badge'}
            </div>
            ${achievementDescription ? `<div style="font-size: 16px; opacity: 0.9; margin-top: 8px;">${achievementDescription}</div>` : ''}
          </div>
        </div>
        <p style="${getParagraphStyle()}">
          You're doing incredible! Keep earning more achievements! 🌟
        </p>
        <div style="${getCtaContainerStyle()}">
          <a href="${APP_URL}" style="${getCtaButtonStyle()}">View All Achievements →</a>
        </div>
        <p style="${getParagraphStyle()}">
          So proud of you!<br>
          <strong>Ory</strong> 🦉
        </p>
      </div>
    </div>
    ${getEmailFooter()}
  `
}

function generateLevelUpEmail(displayName: string, level: number, previousLevel: number, xp?: number): string {
  return `
    ${getEmailHeader('excited')}
    <div style="${getContainerStyle()}">
      <div style="${getContentStyle()}">
        <div style="text-align: center; margin-bottom: 30px;">
          <img src="${ORY_EXCITED_URL}" alt="Ory" style="width: 120px; height: 120px; border-radius: 50%;" />
        </div>
        <h1 style="${getHeadingStyle()}">⭐ Level Up! ⭐</h1>
        <p style="${getParagraphStyle()}">Hi ${displayName},</p>
        <p style="${getParagraphStyle()}">
          Congratulations! You've leveled up from <strong>Level ${previousLevel}</strong> to <strong>Level ${level}</strong>! 🎉
        </p>
        <div style="${getStatsBoxStyle()}">
          <div style="text-align: center; padding: 30px; background: linear-gradient(135deg, #1E3A8A 0%, #3B82F6 100%); border-radius: 12px; color: white; margin: 20px 0;">
            <div style="font-size: 14px; opacity: 0.9; margin-bottom: 8px;">New Level</div>
            <div style="font-size: 64px; font-weight: bold; margin-bottom: 8px;">
              ${level}
            </div>
            ${xp ? `<div style="font-size: 16px; opacity: 0.9;">${xp.toLocaleString()} XP</div>` : ''}
          </div>
        </div>
        <p style="${getParagraphStyle()}">
          Your trading skills are improving! Keep learning and growing! 🚀
        </p>
        <div style="${getCtaContainerStyle()}">
          <a href="${APP_URL}" style="${getCtaButtonStyle()}">Continue Learning →</a>
        </div>
        <p style="${getParagraphStyle()}">
          Amazing progress!<br>
          <strong>Ory</strong> 🦉
        </p>
      </div>
    </div>
    ${getEmailFooter()}
  `
}

function generateMarketUpdateEmail(displayName: string, newsTitle?: string, newsSummary?: string): string {
  return `
    ${getEmailHeader('friendly')}
    <div style="${getContainerStyle()}">
      <div style="${getContentStyle()}">
        <h1 style="${getHeadingStyle()}">📈 Market Update</h1>
        <p style="${getParagraphStyle()}">Hi ${displayName},</p>
        <p style="${getParagraphStyle()}">
          Here's what's happening in the markets today:
        </p>
        ${newsTitle ? `
          <div style="${getFeatureBoxStyle()}">
            <h3 style="${getSubheadingStyle()}">${newsTitle}</h3>
            ${newsSummary ? `<p style="${getParagraphStyle()}">${newsSummary}</p>` : ''}
          </div>
        ` : `
          <div style="${getFeatureBoxStyle()}">
            <p style="${getParagraphStyle()}">
              Check out the latest market movements and trading opportunities!
            </p>
          </div>
        `}
        <div style="${getCtaContainerStyle()}">
          <a href="${APP_URL}" style="${getCtaButtonStyle()}">View Market Updates →</a>
        </div>
        <p style="${getParagraphStyle()}">
          Stay informed, stay ahead!<br>
          <strong>Ory</strong> 🦉
        </p>
      </div>
    </div>
    ${getEmailFooter()}
  `
}

function generateDailyReminderEmail(displayName: string, streak?: number, portfolioValue?: number): string {
  return `
    ${getEmailHeader('friendly')}
    <div style="${getContainerStyle()}">
      <div style="${getContentStyle()}">
        <div style="text-align: center; margin-bottom: 30px;">
          <img src="${ORY_FRIENDLY_URL}" alt="Ory" style="width: 120px; height: 120px; border-radius: 50%;" />
        </div>
        <h1 style="${getHeadingStyle()}">Don't Forget to Check In! 📊</h1>
        <p style="${getParagraphStyle()}">Hi ${displayName},</p>
        <p style="${getParagraphStyle()}">
          Just a friendly reminder to check your portfolio today! ${streak ? `You're on a ${streak}-day streak—keep it going! 🔥` : 'Start building your streak today!'}
        </p>
        ${portfolioValue ? `
          <div style="${getFeatureBoxStyle()}">
            <p style="margin: 0; font-size: 18px; color: #1E3A8A; text-align: center;">
              💰 Portfolio Value: <strong>$${portfolioValue.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</strong>
            </p>
          </div>
        ` : ''}
        <div style="${getCtaContainerStyle()}">
          <a href="${APP_URL}" style="${getCtaButtonStyle()}">Check My Portfolio →</a>
        </div>
        <p style="${getParagraphStyle()}">
          See you inside!<br>
          <strong>Ory</strong> 🦉
        </p>
      </div>
    </div>
    ${getEmailFooter()}
  `
}

function generateFriendActivityEmail(displayName: string): string {
  return `
    ${getEmailHeader('friendly')}
    <div style="${getContainerStyle()}">
      <div style="${getContentStyle()}">
        <h1 style="${getHeadingStyle()}">👥 Your Friends Are Active!</h1>
        <p style="${getParagraphStyle()}">Hi ${displayName},</p>
        <p style="${getParagraphStyle()}">
          Your friends have been making moves! See what they're up to and don't let them get ahead! 🏆
        </p>
        <div style="${getCtaContainerStyle()}">
          <a href="${APP_URL}" style="${getCtaButtonStyle()}">View Leaderboard →</a>
        </div>
        <p style="${getParagraphStyle()}">
          Time to catch up!<br>
          <strong>Ory</strong> 🦉
        </p>
      </div>
    </div>
    ${getEmailFooter()}
  `
}

// Style Helper Functions

function getEmailHeader(mood: string = 'friendly'): string {
  const oryImage = mood === 'excited' ? ORY_EXCITED_URL : 
                   mood === 'concerned' ? ORY_CONCERNED_URL :
                   mood === 'proud' ? ORY_PROUD_URL : ORY_FRIENDLY_URL

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Orion StockSense</title>
    </head>
    <body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F9FAFB;">
      <table role="presentation" style="width: 100%; border-collapse: collapse;">
        <tr>
          <td style="padding: 20px 0; text-align: center; background: linear-gradient(135deg, #1E3A8A 0%, #3B82F6 100%);">
            <img src="${ORION_LOGO_URL}" alt="Orion StockSense" style="height: 40px; width: auto;" />
          </td>
        </tr>
      </table>
  `
}

function getEmailFooter(): string {
  return `
      <table role="presentation" style="width: 100%; border-collapse: collapse; margin-top: 40px;">
        <tr>
          <td style="padding: 30px 20px; text-align: center; background-color: #1F2937; color: #9CA3AF;">
            <p style="margin: 0 0 10px 0; font-size: 14px;">
              <strong style="color: #FFFFFF;">Orion StockSense</strong>
            </p>
            <p style="margin: 0 0 10px 0; font-size: 12px;">
              Your personal trading playground
            </p>
            <p style="margin: 20px 0 0 0; font-size: 12px;">
              <a href="${APP_URL}/unsubscribe" style="color: #60A5FA; text-decoration: none;">Unsubscribe</a> | 
              <a href="${APP_URL}/settings" style="color: #60A5FA; text-decoration: none;">Email Preferences</a>
            </p>
            <p style="margin: 20px 0 0 0; font-size: 11px; color: #6B7280;">
              © ${new Date().getFullYear()} Orion StockSense. All rights reserved.
            </p>
          </td>
        </tr>
      </table>
    </body>
    </html>
  `
}

function getContainerStyle(): string {
  return 'max-width: 600px; margin: 0 auto; background-color: #FFFFFF;'
}

function getContentStyle(): string {
  return 'padding: 40px 30px;'
}

function getHeadingStyle(): string {
  return 'font-size: 28px; font-weight: bold; color: #1E3A8A; margin: 0 0 20px 0; line-height: 1.3;'
}

function getSubheadingStyle(): string {
  return 'font-size: 18px; font-weight: 600; color: #1E3A8A; margin: 0 0 15px 0;'
}

function getParagraphStyle(): string {
  return 'font-size: 16px; line-height: 1.6; color: #374151; margin: 0 0 20px 0;'
}

function getCtaContainerStyle(): string {
  return 'text-align: center; margin: 30px 0;'
}

function getCtaButtonStyle(color: string = '#3B82F6'): string {
  return `
    display: inline-block;
    padding: 14px 32px;
    background: linear-gradient(135deg, #1E3A8A 0%, #3B82F6 100%);
    color: #FFFFFF !important;
    text-decoration: none;
    border-radius: 8px;
    font-weight: 600;
    font-size: 16px;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  `.replace(/\s+/g, ' ').trim()
}

function getFeatureBoxStyle(): string {
  return 'background-color: #F3F4F6; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #3B82F6;'
}

function getStatsBoxStyle(): string {
  return 'margin: 20px 0;'
}

function getListStyle(): string {
  return 'margin: 0; padding-left: 20px; color: #374151; line-height: 1.8;'
}

// Content Helpers

function getOnboardingSubject(dayNumber: number): string {
  const subjects = [
    'Start Your First Paper Trade!',
    'Learn the Basics',
    'Master Stock Analysis',
    'Climb the Leaderboard!',
    'Maintain Your Streak!',
  ]
  return subjects[dayNumber - 1] || 'Continue Your Journey'
}

function getOnboardingContent(dayNumber: number): string {
  const content = [
    'Welcome! Today, try making your first paper trade. Paper trading lets you practice without risking real money. It\'s the perfect way to learn!',
    'Ready to learn? Check out our interactive lessons on stock market basics. Understanding the fundamentals is key to successful trading.',
    'Learn how to analyze stocks using charts, news, and company data. These skills will help you make better trading decisions.',
    'Compete with friends on the leaderboard! Level up by completing lessons and trades. See how you rank!',
    'Keep the momentum going! Set daily goals and maintain your learning streak. Consistency is the secret to success!',
  ]
  return content[dayNumber - 1] || 'Continue your learning journey!'
}
