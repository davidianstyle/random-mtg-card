import 'package:flutter/material.dart';
import '../services/scryfall_service.dart';

class SearchableMultiSelect extends StatefulWidget {
  final String title;
  final List<String> selectedValues;
  final List<FilterOption> options;
  final Function(List<String>) onChanged;
  final bool isLoading;
  final String? placeholder;
  final Widget? leading;
  final int? maxHeight;

  const SearchableMultiSelect({
    super.key,
    required this.title,
    required this.selectedValues,
    required this.options,
    required this.onChanged,
    this.isLoading = false,
    this.placeholder,
    this.leading,
    this.maxHeight,
  });

  @override
  State<SearchableMultiSelect> createState() => _SearchableMultiSelectState();
}

class _SearchableMultiSelectState extends State<SearchableMultiSelect> {
  // Color constants for better maintainability
  static const Color _cardBackgroundColor =
      Color(0xFF212121); // Colors.grey[900]
  static const Color _primaryTextColor = Colors.white;
  static const Color _secondaryTextColor = Color(0xFFB3B3B3); // Colors.white70
  static const Color _tertiaryTextColor = Color(0xFF8A8A8A); // Colors.white54
  static const Color _dividerColor = Color(0xFF3D3D3D); // Colors.white24
  static const Color _borderColor = Color(0xFF3D3D3D); // Colors.white24
  static const Color _primaryAccentColor = Colors.blue;
  static const Color _errorColor = Colors.red;
  static const Color _chipBackgroundColor = Colors.blue;

  final TextEditingController _searchController = TextEditingController();
  List<FilterOption> _filteredOptions = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      _filteredOptions = widget.options.where((option) {
        return option.label.toLowerCase().contains(query) ||
            option.value.toLowerCase().contains(query) ||
            (option.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  // Utility function to update the selected values list
  List<String> _updateValues(String value, bool add) {
    final newValues = List<String>.from(widget.selectedValues);
    if (add) {
      if (!newValues.contains(value)) {
        newValues.add(value);
      }
    } else {
      newValues.remove(value);
    }
    return newValues;
  }

  void _toggleOption(String value) {
    final isCurrentlySelected = widget.selectedValues.contains(value);
    widget.onChanged(_updateValues(value, !isCurrentlySelected));
  }

  void _removeOption(String value) {
    widget.onChanged(_updateValues(value, false));
  }

  void _clearAll() {
    widget.onChanged([]);
  }

  void _selectAll() {
    widget.onChanged(_filteredOptions.map((option) => option.value).toList());
  }

  // Extract selected item chips display to reduce duplication
  Widget _buildSelectedItemChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: SelectedItemsChips(
        selectedValues: widget.selectedValues,
        options: widget.options,
        onRemove: _removeOption,
      ),
    );
  }

  // Extract expanded selected item chips display
  Widget _buildExpandedSelectedItemChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected:',
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SelectedItemsChips(
            selectedValues: widget.selectedValues,
            options: widget.options,
            onRemove: _removeOption,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _cardBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: widget.leading,
            title: Text(
              widget.title,
              style: const TextStyle(
                color: _primaryTextColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: widget.selectedValues.isNotEmpty
                ? Text(
                    '${widget.selectedValues.length} selected',
                    style: const TextStyle(color: _secondaryTextColor),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.selectedValues.isNotEmpty)
                  IconButton(
                    icon:
                        const Icon(Icons.clear_all, color: _secondaryTextColor),
                    onPressed: _clearAll,
                    tooltip: 'Clear all',
                  ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: _secondaryTextColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
          ),

          // Selected items chips (shown when collapsed)
          if (!_isExpanded && widget.selectedValues.isNotEmpty)
            _buildSelectedItemChips(),

          // Expandable content
          if (_isExpanded) ...[
            const Divider(color: _dividerColor),

            // Selected items chips (shown when expanded)
            if (widget.selectedValues.isNotEmpty)
              _buildExpandedSelectedItemChips(),

            // Search field
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: _primaryTextColor),
                decoration: InputDecoration(
                  hintText: widget.placeholder ??
                      'Search ${widget.title.toLowerCase()}...',
                  hintStyle: const TextStyle(color: _tertiaryTextColor),
                  prefixIcon:
                      const Icon(Icons.search, color: _secondaryTextColor),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: _secondaryTextColor),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _primaryAccentColor),
                  ),
                ),
              ),
            ),

            // Select all / Clear all buttons
            if (_filteredOptions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _selectAll,
                      child: const Text('Select All',
                          style: TextStyle(color: _primaryAccentColor)),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: _clearAll,
                      child: const Text('Clear All',
                          style: TextStyle(color: _errorColor)),
                    ),
                  ],
                ),
              ),

            // Options list
            if (widget.isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: CircularProgressIndicator(color: _primaryAccentColor),
                ),
              )
            else if (_filteredOptions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'No options found',
                    style: TextStyle(color: _tertiaryTextColor),
                  ),
                ),
              )
            else
              SizedBox(
                height: widget.maxHeight?.toDouble() ?? 300,
                child: ListView.builder(
                  itemCount: _filteredOptions.length,
                  itemBuilder: (context, index) {
                    final option = _filteredOptions[index];
                    final isSelected =
                        widget.selectedValues.contains(option.value);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (bool? value) {
                        _toggleOption(option.value);
                      },
                      title: Text(
                        option.label,
                        style: TextStyle(
                          color: isSelected
                              ? _primaryTextColor
                              : _secondaryTextColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: option.description != null
                          ? Text(
                              option.description!,
                              style: const TextStyle(
                                  color: _tertiaryTextColor, fontSize: 12),
                            )
                          : null,
                      activeColor: _primaryAccentColor,
                      checkColor: _primaryTextColor,
                      dense: true,
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// Helper widget for displaying selected items as chips
class SelectedItemsChips extends StatelessWidget {
  final List<String> selectedValues;
  final List<FilterOption> options;
  final Function(String) onRemove;
  final String? emptyText;

  const SelectedItemsChips({
    super.key,
    required this.selectedValues,
    required this.options,
    required this.onRemove,
    this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedValues.isEmpty) {
      return Text(
        emptyText ?? 'No items selected',
        style: const TextStyle(
            color: _SearchableMultiSelectState._tertiaryTextColor),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: selectedValues.map((value) {
        final option = options.firstWhere(
          (opt) => opt.value == value,
          orElse: () => FilterOption(value: value, label: value),
        );

        return Chip(
          label: Text(
            option.label,
            style: const TextStyle(
                color: _SearchableMultiSelectState._primaryTextColor,
                fontSize: 12),
          ),
          backgroundColor: _SearchableMultiSelectState._chipBackgroundColor,
          deleteIcon: const Icon(Icons.close,
              color: _SearchableMultiSelectState._primaryTextColor, size: 16),
          onDeleted: () => onRemove(value),
        );
      }).toList(),
    );
  }
}
