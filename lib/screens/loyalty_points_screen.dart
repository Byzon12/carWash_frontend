import 'package:flutter/material.dart';
import 'dart:convert';
import '../api/api_connect.dart';
import '../models/loyalty_models.dart';

class LoyaltyPointsScreen extends StatefulWidget {
  const LoyaltyPointsScreen({super.key});

  @override
  State<LoyaltyPointsScreen> createState() => _LoyaltyPointsScreenState();
}

class _LoyaltyPointsScreenState extends State<LoyaltyPointsScreen> {
  LoyaltyDashboardData? _loyaltyData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLoyaltyDashboard();
  }

  Future<void> _loadLoyaltyDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiConnect.getLoyaltyDashboard();

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _loyaltyData = LoyaltyDashboardData.fromJson(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load loyalty data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading loyalty data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Loyalty Points'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildErrorWidget()
              : _loyaltyData != null
              ? _buildLoyaltyDashboard()
              : const Center(child: Text('No data available')),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadLoyaltyDashboard,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltyDashboard() {
    final data = _loyaltyData!;
    return RefreshIndicator(
      onRefresh: _loadLoyaltyDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(data.customerInfo),
            const SizedBox(height: 16),
            _buildPointsOverviewCard(data.loyaltyStats),
            const SizedBox(height: 16),
            _buildTierProgressCard(data.loyaltyStats),
            const SizedBox(height: 16),
            _buildPointsBreakdownCard(data.loyaltyStats),
            const SizedBox(height: 16),
            _buildQuickActionsCard(data.quickActions),
            const SizedBox(height: 16),
            _buildRecentTransactionsCard(data.loyaltyStats),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(LoyaltyCustomerInfo customerInfo) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[600]!, Colors.blue[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    customerInfo.username.isNotEmpty
                        ? customerInfo.username[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        customerInfo.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Member since ${customerInfo.memberSince}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsOverviewCard(LoyaltyStats stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stars, color: Colors.amber[600], size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Points Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Current Points',
                    stats.currentPoints.toString(),
                    Colors.blue[600]!,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Earned',
                    stats.totalEarned.toString(),
                    Colors.green[600]!,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Redeemed',
                    stats.totalRedeemed.toString(),
                    Colors.orange[600]!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTierProgressCard(LoyaltyStats stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getTierIcon(stats.loyaltyTier),
                  color: _getTierColor(stats.loyaltyTier),
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  '${stats.loyaltyTier} Tier',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Progress to ${stats.nextTierProgress.nextTier}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: stats.nextTierProgress.progressPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getTierColor(stats.nextTierProgress.nextTier),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stats.nextTierProgress.message,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children:
                  stats.tierBenefits
                      .map(
                        (benefit) => Chip(
                          label: Text(
                            benefit,
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: Colors.blue[50],
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsBreakdownCard(LoyaltyStats stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.purple, size: 28),
                SizedBox(width: 8),
                Text(
                  'Points Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBreakdownItem(
              'From Bookings',
              stats.pointsBreakdown.fromBookings,
              Icons.local_car_wash,
              Colors.blue[600]!,
            ),
            _buildBreakdownItem(
              'From Logins',
              stats.pointsBreakdown.fromLogins,
              Icons.login,
              Colors.green[600]!,
            ),
            _buildBreakdownItem(
              'From Bonuses',
              stats.pointsBreakdown.fromBonuses,
              Icons.card_giftcard,
              Colors.orange[600]!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(
    String label,
    int points,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            '$points pts',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(List<QuickAction> actions) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flash_on, color: Colors.amber, size: 28),
                SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...actions.map((action) => _buildQuickActionItem(action)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(QuickAction action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => _handleQuickAction(action.action),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                _getActionIcon(action.icon),
                color: Colors.blue[600],
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      action.description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsCard(LoyaltyStats stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.grey, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _showFullHistory(),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            stats.recentTransactions.isEmpty
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No recent transactions',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
                : Column(
                  children:
                      stats.recentTransactions
                          .take(3)
                          .map(
                            (transaction) => _buildTransactionItem(transaction),
                          )
                          .toList(),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(LoyaltyTransaction transaction) {
    final isEarned = transaction.points > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isEarned ? Icons.add_circle : Icons.remove_circle,
            color: isEarned ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatDate(transaction.date),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${isEarned ? '+' : ''}${transaction.points} pts',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isEarned ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTierIcon(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return Icons.workspace_premium;
      case 'silver':
        return Icons.military_tech;
      case 'gold':
        return Icons.emoji_events;
      case 'platinum':
        return Icons.diamond;
      default:
        return Icons.stars;
    }
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return Colors.brown[600]!;
      case 'silver':
        return Colors.grey[600]!;
      case 'gold':
        return Colors.amber[600]!;
      case 'platinum':
        return Colors.purple[600]!;
      default:
        return Colors.blue[600]!;
    }
  }

  IconData _getActionIcon(String icon) {
    switch (icon) {
      case 'car_wash':
        return Icons.local_car_wash;
      case 'history':
        return Icons.history;
      case 'redeem':
        return Icons.redeem;
      default:
        return Icons.home;
    }
  }

  void _handleQuickAction(String action) {
    switch (action) {
      case 'book_service':
        Navigator.pop(context);
        // Navigate to booking screen
        break;
      case 'view_history':
        _showFullHistory();
        break;
      case 'redeem_points':
        _showRedeemDialog();
        break;
    }
  }

  void _showFullHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoyaltyHistoryScreen()),
    );
  }

  void _showRedeemDialog() {
    // Implementation for redemption dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Redeem Points'),
            content: const Text('Redemption feature coming soon!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class LoyaltyHistoryScreen extends StatefulWidget {
  const LoyaltyHistoryScreen({super.key});

  @override
  State<LoyaltyHistoryScreen> createState() => _LoyaltyHistoryScreenState();
}

class _LoyaltyHistoryScreenState extends State<LoyaltyHistoryScreen> {
  List<LoyaltyTransaction> _transactions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiConnect.getLoyaltyHistory();

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _transactions =
              (data['transactions'] as List<dynamic>? ?? [])
                  .map((tx) => LoyaltyTransaction.fromJson(tx))
                  .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load transaction history';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading transaction history: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!),
                    ElevatedButton(
                      onPressed: _loadHistory,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : _transactions.isEmpty
              ? const Center(child: Text('No transaction history available'))
              : ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final transaction = _transactions[index];
                  final isEarned = transaction.points > 0;
                  return ListTile(
                    leading: Icon(
                      isEarned ? Icons.add_circle : Icons.remove_circle,
                      color: isEarned ? Colors.green : Colors.red,
                    ),
                    title: Text(transaction.description),
                    subtitle: Text(
                      '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                    ),
                    trailing: Text(
                      '${isEarned ? '+' : ''}${transaction.points} pts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isEarned ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
