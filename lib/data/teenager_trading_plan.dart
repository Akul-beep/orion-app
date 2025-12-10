class TeenagerTradingPlan {
  static List<Map<String, dynamic>> get30DayTradingPlan() {
    return [
      {
        'week': 1,
        'title': 'Foundation - Making Your First Dollar',
        'days': [
          {
            'day': 1,
            'title': 'Your First Real Trade',
            'focus': 'Making your first real trade using Orion',
            'earning_goal': '\$5-25',
            'duration': '30 minutes',
            'lessons': [
              {
                'title': 'Set Up Your Real Trading Account in Orion',
                'content': 'Connect your bank account to Orion. Start with \$25-100 real money.',
                'action': 'In Orion, connect your bank account and deposit \$25-100',
                'earning_potential': 'Real money gains from day 1',
                'time_required': '10 minutes',
                'type': 'setup'
              },
              {
                'title': 'Warren Buffett\'s Contrarian Strategy',
                'content': 'Be fearful when others are greedy, and greedy when others are fearful.',
                'action': 'Use Orion\'s scanner to find a stock down 3%+ and make your first real trade',
                'earning_potential': '3-10% gains when it bounces back',
                'time_required': '15 minutes',
                'type': 'strategy'
              },
              {
                'title': 'Your First Real Trade - AAPL, TSLA, or GOOGL',
                'content': 'Pick one stock you know and buy 1-2 shares with your real money.',
                'action': 'Execute your first real trade in Orion - buy 1-2 shares of a company you know',
                'earning_potential': 'Real money gains',
                'time_required': '5 minutes',
                'type': 'trading'
              }
            ]
          }
        ]
      }
    ];
  }
}