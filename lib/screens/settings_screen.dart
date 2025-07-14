import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/scryfall_service.dart';
import '../services/config_service.dart';
import '../widgets/searchable_multiselect.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ScryfallService _scryfallService = ScryfallService.instance;
  final ConfigService _config = ConfigService.instance;

  // Filter options
  List<FilterOption> _availableSets = [];
  List<FilterOption> _availableColors = [];
  List<FilterOption> _availableCardTypes = [];
  List<FilterOption> _availableCreatureTypes = [];
  List<FilterOption> _availableRarities = [];
  List<FilterOption> _availableFormats = [];

  // Current selections
  List<String> _selectedSets = [];
  List<String> _selectedColors = [];
  List<String> _selectedCardTypes = [];
  List<String> _selectedCreatureTypes = [];
  List<String> _selectedRarities = [];
  List<String> _selectedFormats = [];

  // Loading states
  bool _isLoadingSets = false;
  bool _isLoadingCardTypes = false;
  bool _isLoadingCreatureTypes = false;
  bool _isLoadingColors = false;
  bool _isLoadingRarities = false;
  bool _isLoadingFormats = false;

  // General settings
  bool _filtersEnabled = false;
  bool _autoRefreshEnabled = false;
  int _autoRefreshInterval = 30;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
    _loadFilterOptions();
  }

  void _loadCurrentSettings() {
    setState(() {
      _filtersEnabled = _config.filtersEnabled;
      _autoRefreshEnabled = _config.autoRefreshInterval > 0;
      _autoRefreshInterval = _config.autoRefreshInterval;
      
      _selectedSets = List.from(_config.filterSets);
      _selectedColors = List.from(_config.filterColors);
      _selectedCardTypes = List.from(_config.filterCardTypes);
      _selectedCreatureTypes = List.from(_config.filterCreatureTypes);
      _selectedRarities = List.from(_config.filterRarity);
      _selectedFormats = [_config.filterFormat];
    });
  }

  void _loadFilterOptions() async {
    // Load all filter options in parallel
    setState(() {
      _isLoadingSets = true;
      _isLoadingCardTypes = true;
      _isLoadingCreatureTypes = true;
      _isLoadingColors = true;
      _isLoadingRarities = true;
      _isLoadingFormats = true;
    });

    final results = await Future.wait([
      _scryfallService.getAvailableSets(),
      _scryfallService.getAvailableColors(),
      _scryfallService.getAvailableCardTypes(),
      _scryfallService.getAvailableCreatureTypes(),
      _scryfallService.getAvailableRarities(),
      _scryfallService.getAvailableFormats(),
    ]);

    setState(() {
      _availableSets = results[0];
      _availableColors = results[1];
      _availableCardTypes = results[2];
      _availableCreatureTypes = results[3];
      _availableRarities = results[4];
      _availableFormats = results[5];
      
      _isLoadingSets = false;
      _isLoadingCardTypes = false;
      _isLoadingCreatureTypes = false;
      _isLoadingColors = false;
      _isLoadingRarities = false;
      _isLoadingFormats = false;
    });
  }

  void _saveSettings() async {
    // Save filter settings
    await _config.updateConfig('filters.enabled', _filtersEnabled);
    await _config.updateConfig('filters.sets', _selectedSets);
    await _config.updateConfig('filters.colors', _selectedColors);
    await _config.updateConfig('filters.card_types', _selectedCardTypes);
    await _config.updateConfig('filters.creature_types', _selectedCreatureTypes);
    await _config.updateConfig('filters.rarity', _selectedRarities);
    await _config.updateConfig('filters.format', _selectedFormats.isNotEmpty ? _selectedFormats.first : 'standard');
    
    // Save general settings
    await _config.updateConfig('display.auto_refresh_interval', _autoRefreshEnabled ? _autoRefreshInterval : 0);
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _resetSettings() async {
    await _config.resetToDefaults();
    _loadCurrentSettings();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings reset to defaults!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _refreshFilterOptions() {
    _scryfallService.clearFilterCache();
    _loadFilterOptions();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filter options refreshed!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshFilterOptions,
            tooltip: 'Refresh filter options',
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _resetSettings,
            tooltip: 'Reset to defaults',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Settings
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'General Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Enable Filters
                    SwitchListTile(
                      value: _filtersEnabled,
                      onChanged: (value) {
                        setState(() {
                          _filtersEnabled = value;
                        });
                      },
                      title: const Text(
                        'Enable Filters',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Apply filters when fetching random cards',
                        style: TextStyle(color: Colors.white70),
                      ),
                      activeColor: Colors.blue,
                    ),
                    
                    // Auto Refresh
                    SwitchListTile(
                      value: _autoRefreshEnabled,
                      onChanged: (value) {
                        setState(() {
                          _autoRefreshEnabled = value;
                        });
                      },
                      title: const Text(
                        'Auto Refresh',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Automatically load new cards every ${_autoRefreshInterval}s',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      activeColor: Colors.blue,
                    ),
                    
                    // Auto Refresh Interval
                    if (_autoRefreshEnabled)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Text(
                              'Interval: ',
                              style: TextStyle(color: Colors.white70),
                            ),
                            Expanded(
                              child: Slider(
                                value: _autoRefreshInterval.toDouble(),
                                min: 5,
                                max: 120,
                                divisions: 23,
                                label: '${_autoRefreshInterval}s',
                                onChanged: (value) {
                                  setState(() {
                                    _autoRefreshInterval = value.round();
                                  });
                                },
                                activeColor: Colors.blue,
                              ),
                            ),
                            Text(
                              '${_autoRefreshInterval}s',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Filter Settings Header
            const Text(
              'Filter Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure which cards to include when fetching random cards',
              style: TextStyle(color: Colors.white70),
            ),
            
            const SizedBox(height: 16),
            
            // Sets Filter
            SearchableMultiSelect(
              title: 'Sets',
              selectedValues: _selectedSets,
              options: _availableSets,
              onChanged: (values) {
                setState(() {
                  _selectedSets = values;
                });
              },
              isLoading: _isLoadingSets,
              leading: const Icon(Icons.library_books, color: Colors.green),
              placeholder: 'Search sets by name or code...',
              maxHeight: 250,
            ),
            
            const SizedBox(height: 16),
            
            // Colors Filter
            SearchableMultiSelect(
              title: 'Colors',
              selectedValues: _selectedColors,
              options: _availableColors,
              onChanged: (values) {
                setState(() {
                  _selectedColors = values;
                });
              },
              isLoading: _isLoadingColors,
              leading: const Icon(Icons.palette, color: Colors.purple),
              placeholder: 'Search colors...',
              maxHeight: 200,
            ),
            
            const SizedBox(height: 16),
            
            // Card Types Filter
            SearchableMultiSelect(
              title: 'Card Types',
              selectedValues: _selectedCardTypes,
              options: _availableCardTypes,
              onChanged: (values) {
                setState(() {
                  _selectedCardTypes = values;
                });
              },
              isLoading: _isLoadingCardTypes,
              leading: const Icon(Icons.category, color: Colors.purple),
              placeholder: 'Search card types...',
              maxHeight: 200,
            ),
            
            const SizedBox(height: 16),
            
            // Creature Types Filter
            SearchableMultiSelect(
              title: 'Creature Types',
              selectedValues: _selectedCreatureTypes,
              options: _availableCreatureTypes,
              onChanged: (values) {
                setState(() {
                  _selectedCreatureTypes = values;
                });
              },
              isLoading: _isLoadingCreatureTypes,
              leading: const Icon(Icons.pets, color: Colors.brown),
              placeholder: 'Search creature types...',
              maxHeight: 300,
            ),
            
            const SizedBox(height: 16),
            
            // Rarity Filter
            SearchableMultiSelect(
              title: 'Rarity',
              selectedValues: _selectedRarities,
              options: _availableRarities,
              onChanged: (values) {
                setState(() {
                  _selectedRarities = values;
                });
              },
              isLoading: _isLoadingRarities,
              leading: const Icon(Icons.star, color: Colors.amber),
              placeholder: 'Search rarities...',
              maxHeight: 200,
            ),
            
            const SizedBox(height: 16),
            
            // Format Filter (single select)
            SearchableMultiSelect(
              title: 'Format',
              selectedValues: _selectedFormats,
              options: _availableFormats,
              onChanged: (values) {
                setState(() {
                  // Only allow single selection for format
                  _selectedFormats = values.isNotEmpty ? [values.last] : [];
                });
              },
              isLoading: _isLoadingFormats,
              leading: const Icon(Icons.gavel, color: Colors.orange),
              placeholder: 'Search formats...',
              maxHeight: 250,
            ),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Reset to Defaults'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Settings'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
} 