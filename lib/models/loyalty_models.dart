// Loyalty Points Models
class LoyaltyCustomerInfo {
  final String username;
  final String email;
  final String memberSince;

  LoyaltyCustomerInfo({
    required this.username,
    required this.email,
    required this.memberSince,
  });

  factory LoyaltyCustomerInfo.fromJson(Map<String, dynamic> json) {
    return LoyaltyCustomerInfo(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      memberSince: json['member_since'] ?? '',
    );
  }
}

class PointsBreakdown {
  final int fromBookings;
  final int fromLogins;
  final int fromBonuses;

  PointsBreakdown({
    required this.fromBookings,
    required this.fromLogins,
    required this.fromBonuses,
  });

  factory PointsBreakdown.fromJson(Map<String, dynamic> json) {
    return PointsBreakdown(
      fromBookings: json['from_bookings'] ?? 0,
      fromLogins: json['from_logins'] ?? 0,
      fromBonuses: json['from_bonuses'] ?? 0,
    );
  }
}

class NextTierProgress {
  final String nextTier;
  final int pointsNeeded;
  final double progressPercentage;
  final String message;

  NextTierProgress({
    required this.nextTier,
    required this.pointsNeeded,
    required this.progressPercentage,
    required this.message,
  });

  factory NextTierProgress.fromJson(Map<String, dynamic> json) {
    return NextTierProgress(
      nextTier: json['next_tier'] ?? '',
      pointsNeeded: json['points_needed'] ?? 0,
      progressPercentage: (json['progress_percentage'] ?? 0.0).toDouble(),
      message: json['message'] ?? '',
    );
  }
}

class LoyaltyTransaction {
  final String id;
  final String transactionType;
  final int points;
  final String description;
  final DateTime date;
  final String status;

  LoyaltyTransaction({
    required this.id,
    required this.transactionType,
    required this.points,
    required this.description,
    required this.date,
    required this.status,
  });

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransaction(
      id: json['id']?.toString() ?? '',
      transactionType: json['transaction_type'] ?? '',
      points: json['points'] ?? 0,
      description: json['description'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? '',
    );
  }
}

class LoyaltyStats {
  final int currentPoints;
  final String loyaltyTier;
  final int totalEarned;
  final int totalRedeemed;
  final int netPoints;
  final PointsBreakdown pointsBreakdown;
  final List<String> tierBenefits;
  final NextTierProgress nextTierProgress;
  final List<LoyaltyTransaction> recentTransactions;
  final int totalTransactions;

  LoyaltyStats({
    required this.currentPoints,
    required this.loyaltyTier,
    required this.totalEarned,
    required this.totalRedeemed,
    required this.netPoints,
    required this.pointsBreakdown,
    required this.tierBenefits,
    required this.nextTierProgress,
    required this.recentTransactions,
    required this.totalTransactions,
  });

  factory LoyaltyStats.fromJson(Map<String, dynamic> json) {
    return LoyaltyStats(
      currentPoints: json['current_points'] ?? 0,
      loyaltyTier: json['loyalty_tier'] ?? 'Bronze',
      totalEarned: json['total_earned'] ?? 0,
      totalRedeemed: json['total_redeemed'] ?? 0,
      netPoints: json['net_points'] ?? 0,
      pointsBreakdown: PointsBreakdown.fromJson(json['points_breakdown'] ?? {}),
      tierBenefits: List<String>.from(json['tier_benefits'] ?? []),
      nextTierProgress: NextTierProgress.fromJson(
        json['next_tier_progress'] ?? {},
      ),
      recentTransactions:
          (json['recent_transactions'] as List<dynamic>? ?? [])
              .map((tx) => LoyaltyTransaction.fromJson(tx))
              .toList(),
      totalTransactions: json['total_transactions'] ?? 0,
    );
  }
}

class QuickAction {
  final String title;
  final String description;
  final String icon;
  final String action;

  QuickAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.action,
  });

  factory QuickAction.fromJson(Map<String, dynamic> json) {
    return QuickAction(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      action: json['action'] ?? '',
    );
  }
}

class LoyaltyDashboardData {
  final bool success;
  final LoyaltyCustomerInfo customerInfo;
  final LoyaltyStats loyaltyStats;
  final List<QuickAction> quickActions;

  LoyaltyDashboardData({
    required this.success,
    required this.customerInfo,
    required this.loyaltyStats,
    required this.quickActions,
  });

  factory LoyaltyDashboardData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return LoyaltyDashboardData(
      success: json['success'] ?? false,
      customerInfo: LoyaltyCustomerInfo.fromJson(data['customer_info'] ?? {}),
      loyaltyStats: LoyaltyStats.fromJson(data['loyalty_stats'] ?? {}),
      quickActions:
          (data['quick_actions'] as List<dynamic>? ?? [])
              .map((action) => QuickAction.fromJson(action))
              .toList(),
    );
  }
}
