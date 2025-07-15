import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/card_provider.dart';
import '../widgets/card_widget.dart';
import '../widgets/favorite_indicator.dart';
import '../widgets/card_metadata_overlay.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_overlay.dart';
import '../widgets/menu_overlay.dart';
import '../services/config_service.dart';
import '../services/service_locator.dart';
import '../utils/logger.dart';
import '../utils/performance_monitor.dart';

class CardDisplayScreen extends StatefulWidget {
  const CardDisplayScreen({super.key});

  @override
  State<CardDisplayScreen> createState() => _CardDisplayScreenState();
}

class _CardDisplayScreenState extends State<CardDisplayScreen>
    with LoggerExtension, PerformanceMonitoring {
  late final ConfigService _config;
  bool _showMenu = false;

  @override
  void initState() {
    super.initState();
    try {
      _config = getService<ConfigService>();
      _initializeProviders();
    } catch (e, stackTrace) {
      logError('Failed to initialize card display screen',
          error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _initializeProviders() async {
    return timeAsync('initializeProviders', () async {
      try {
        logInfo('Initializing card display screen providers');

        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final cardProvider = Provider.of<CardProvider>(context, listen: false);

        await appProvider.initialize();
        await cardProvider.initialize();

        // Start auto-refresh if configured
        if (_config.autoRefreshInterval > 0) {
          cardProvider.startAutoRefresh();
          logInfo('Auto-refresh enabled', context: {
            'interval_seconds': _config.autoRefreshInterval,
          });
        }

        logInfo('Card display screen providers initialized successfully');
      } catch (e, stackTrace) {
        logError('Failed to initialize providers',
            error: e, stackTrace: stackTrace);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer2<AppProvider, CardProvider>(
        builder: (context, appProvider, cardProvider, child) {
          return Stack(
            children: [
              // Main card display area
              _buildCardArea(appProvider, cardProvider),

              // Menu button (top-left)
              Positioned(
                top: 20,
                left: 20,
                child: SafeArea(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _showMenu = true;
                        });
                      },
                      tooltip: 'Open menu',
                    ),
                  ),
                ),
              ),

              // Favorite indicator (top-right)
              if (_config.favoriteIndicator && cardProvider.currentCard != null)
                Positioned(
                  top: 20,
                  right: 20,
                  child: SafeArea(
                    child: FavoriteIndicator(
                      isFavorite:
                          appProvider.isFavorite(cardProvider.currentCard!.id),
                    ),
                  ),
                ),

              // Metadata overlay (bottom)
              if (appProvider.showMetadata && cardProvider.currentCard != null)
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: CardMetadataOverlay(
                    card: cardProvider.currentCard!,
                  ),
                ),

              // Loading indicator
              if (appProvider.isLoading || cardProvider.isLoading)
                const LoadingIndicator(),

              // Error overlay
              if (appProvider.errorMessage != null ||
                  cardProvider.errorMessage != null)
                ErrorOverlay(
                  message:
                      appProvider.errorMessage ?? cardProvider.errorMessage!,
                  onDismiss: () {
                    logDebug('Error overlay dismissed');
                    appProvider.clearError();
                    cardProvider.clearError();
                  },
                ),

              // Menu overlay
              if (_showMenu)
                MenuOverlay(
                  onClose: () {
                    setState(() {
                      _showMenu = false;
                    });
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCardArea(AppProvider appProvider, CardProvider cardProvider) {
    return GestureDetector(
      // Single tap - toggle metadata
      onTap: _config.tapMetadataToggle
          ? () {
              appProvider.toggleMetadata();
              if (appProvider.showMetadata) {
                appProvider.autoHideMetadata();
              }
            }
          : null,

      // Double tap - toggle favorite
      onDoubleTap: _config.doubleTapFavorite && cardProvider.currentCard != null
          ? () {
              appProvider.toggleFavorite(cardProvider.currentCard!);
            }
          : null,

      // Long press - show card details (future feature)
      onLongPress: _config.longPressDetails
          ? () {
              // TODO: Implement card details view
              debugPrint('Long press detected - show card details');
            }
          : null,

      // Horizontal swipe - navigate cards
      onHorizontalDragEnd: _config.swipeNavigation
          ? (details) {
              const sensitivity = 100;
              final velocity = details.primaryVelocity ?? 0;

              if (velocity.abs() > sensitivity) {
                final isLeftSwipe = velocity < 0;
                cardProvider.handleSwipe(isLeftSwipe);
              }
            }
          : null,

      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: cardProvider.currentCard != null
            ? CardWidget(card: cardProvider.currentCard!)
            : const Center(
                child: Text(
                  'No card loaded',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
              ),
      ),
    );
  }
}
