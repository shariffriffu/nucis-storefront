import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/activity_provider.dart';
import '../../models/activity.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  String _selectedFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _expandedIndex;

  final List<String> _filters = const ['ALL', 'ORDERS', 'SIGNALS', 'WARNINGS', 'ERRORS'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activities = ref.watch(activityProvider);

    // Perform query and category filtering
    final filteredActivities = activities.where((activity) {
      // 1. Filter by category
      bool matchesCategory = true;
      if (_selectedFilter == 'ORDERS') {
        matchesCategory = activity.type == 'buy' || activity.type == 'sell';
      } else if (_selectedFilter == 'SIGNALS') {
        matchesCategory = activity.type == 'entry' || activity.type == 'exit';
      } else if (_selectedFilter == 'WARNINGS') {
        matchesCategory = activity.type == 'warning';
      } else if (_selectedFilter == 'ERRORS') {
        matchesCategory = activity.type == 'error';
      }

      // 2. Filter by search query
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        matchesSearch = activity.message.toLowerCase().contains(query) ||
            activity.details.toLowerCase().contains(query) ||
            activity.type.toLowerCase().contains(query);
      }

      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Search Bar & Filter list
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search signals, orders, logs...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = _selectedFilter == filter;
                      return ChoiceChip(
                        label: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF8E92B2),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF6366F1),
                        backgroundColor: const Color(0xFF14151F),
                        checkmarkColor: Colors.white,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = filter;
                              _expandedIndex = null; // collapse on filter change
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main Activity List
          Expanded(
            child: filteredActivities.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredActivities.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final activity = filteredActivities[index];
                      final isExpanded = _expandedIndex == index;
                      return _buildActivityTile(activity, index, isExpanded);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(Activity activity, int index, bool isExpanded) {
    Color badgeColor;
    String badgeText;
    IconData icon;

    switch (activity.type) {
      case 'buy':
        badgeColor = const Color(0xFF10B981); // Emerald Green
        badgeText = 'BUY ORDER';
        icon = Icons.shopping_cart_outlined;
        break;
      case 'sell':
        badgeColor = const Color(0xFFEF4444); // Crimson Red
        badgeText = 'SELL ORDER';
        icon = Icons.shopping_basket_outlined;
        break;
      case 'entry':
        badgeColor = const Color(0xFF6366F1); // Indigo
        badgeText = 'ENTRY SIGNAL';
        icon = Icons.sensors_rounded;
        break;
      case 'exit':
        badgeColor = const Color(0xFFF59E0B); // Amber
        badgeText = 'EXIT SIGNAL';
        icon = Icons.sensors_off_rounded;
        break;
      case 'warning':
        badgeColor = const Color(0xFFEAB308); // Yellow
        badgeText = 'WARNING';
        icon = Icons.warning_amber_rounded;
        break;
      case 'error':
        badgeColor = const Color(0xFFEF4444); // Red
        badgeText = 'ERROR';
        icon = Icons.error_outline_rounded;
        break;
      default:
        badgeColor = const Color(0xFF8F90A6);
        badgeText = 'LOG';
        icon = Icons.info_outline;
    }

    return Card(
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedIndex = isExpanded ? null : index;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visual Icon indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: badgeColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Badge & Time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: badgeColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Text(
                              DateFormat('HH:mm:ss').format(activity.timestamp),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF8E92B2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Log Message
                        Text(
                          activity.message,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isExpanded && activity.details.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFF232536)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1017),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    activity.details,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFFF3F4F6),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: const Color(0xFF8E92B2).withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text(
            'No matching activities found',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF8E92B2),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
