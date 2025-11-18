import 'package:flutter/material.dart';
import 'package:pdf_professional_flutter/screens/scan/scan_document_screen_new.dart';
import 'package:pdf_professional_flutter/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/premium_provider.dart';
import '../../services/ad_service.dart';
import '../../config/app_theme.dart';
import 'pdf_list_screen.dart';
import 'converter_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late AdService _adService;

  final List<Widget> _screens = [
    const PdfListScreen(),
    const ScanDocumentScreen(),
    const ConverterScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _adService = context.read<AdService>();
    
    // Load ads if not premium
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isPremium = context.read<PremiumProvider>().isPremium;
      if (!isPremium) {
        _adService.loadBannerAd();
        _adService.loadInterstitialAd();
      }
    });
  }

  @override
  void dispose() {
    _adService.disposeBannerAd();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.appBarTheme.backgroundColor ?? Colors.white,
          border: Border(
            top: BorderSide(
              color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                  isSelected: _selectedIndex == 0,
                  onTap: () => _onItemTapped(0),
                ),
                _NavBarItem(
                  icon: Icons.document_scanner_outlined,
                  selectedIcon: Icons.document_scanner,
                  label: 'Scanner',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onItemTapped(1),
                ),
                _NavBarItem(
                  icon: Icons.refresh_outlined,
                  selectedIcon: Icons.refresh,
                  label: 'Convert',
                  isSelected: _selectedIndex == 2,
                  onTap: () => _onItemTapped(2),
                ),
                _NavBarItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: 'Setting',
                  isSelected: _selectedIndex == 3,
                  onTap: () => _onItemTapped(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? AppTheme.primaryColor
        : (theme.brightness == Brightness.dark
            ? const Color(0xFF9CA3AF)
            : const Color(0xFF4B5563));

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
