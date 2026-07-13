import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'current_complaints_screen.dart';
import 'past_complaints_screen.dart';
import '../../../../providers/language_provider.dart';
import '../../../../localization/app_localizations.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final lang = languageProvider.currentLanguage;
        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.get('complaints', 'my_complaints', lang)),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  icon: const Icon(Icons.pending_actions),
                  text: AppStrings.get('complaints', 'current', lang),
                ),
                Tab(
                  icon: const Icon(Icons.history),
                  text: AppStrings.get('complaints', 'past', lang),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              CurrentComplaintsScreen(),
              PastComplaintsScreen(),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              // Navigate to file complaint
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${AppStrings.get('complaints', 'file_complaint', lang)} - ${AppStrings.get('complaints', 'feature_coming_soon', lang)}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: Text(AppStrings.get('complaints', 'file_complaint', lang)),
          ),
        );
      },
    );
  }
}
