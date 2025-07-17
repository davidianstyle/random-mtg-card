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

  void _toggleOption(String value) {
    final newValues = List<String>.from(widget.selectedValues);
    if (newValues.contains(value)) {
      newValues.remove(value);
    } else {
      newValues.add(value);
    }
    widget.onChanged(newValues);
  }

  void _removeOption(String value) {
    final newValues = List<String>.from(widget.selectedValues);
    newValues.remove(value);
    widget.onChanged(newValues);
  }

  void _clearAll() {
    widget.onChanged([]);
  }

  void _selectAll() {
    widget.onChanged(_filteredOptions.map((option) => option.value).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: widget.leading,
            title: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: widget.selectedValues.isNotEmpty
                ? Text(
                    '${widget.selectedValues.length} selected',
                    style: const TextStyle(color: Colors.white70),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.selectedValues.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_all, color: Colors.white70),
                    onPressed: _clearAll,
                    tooltip: 'Clear all',
                  ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white70,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: SelectedItemsChips(
                selectedValues: widget.selectedValues,
                options: widget.options,
                onRemove: _removeOption,
              ),
            ),

          // Expandable content
          if (_isExpanded) ...[
            const Divider(color: Colors.white24),

            // Selected items chips (shown when expanded)
            if (widget.selectedValues.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected:',
                      style: TextStyle(
                        color: Colors.white70,
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
              ),

            // Search field
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: widget.placeholder ??
                      'Search ${widget.title.toLowerCase()}...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue),
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
                          style: TextStyle(color: Colors.blue)),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: _clearAll,
                      child: const Text('Clear All',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),

            // Options list
            if (widget.isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.blue),
                ),
              )
            else if (_filteredOptions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'No options found',
                    style: TextStyle(color: Colors.white54),
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
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: option.description != null
                          ? Text(
                              option.description!,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            )
                          : null,
                      activeColor: Colors.blue,
                      checkColor: Colors.white,
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
        style: const TextStyle(color: Colors.white54),
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
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          backgroundColor: Colors.blue,
          deleteIcon: const Icon(Icons.close, color: Colors.white, size: 16),
          onDeleted: () => onRemove(value),
        );
      }).toList(),
    );
  }
}
