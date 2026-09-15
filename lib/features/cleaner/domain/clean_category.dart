import 'clean_item.dart';

class CleanCategory {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final List<CleanItem> items;
  final bool isExpanded;

  const CleanCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.items,
    this.isExpanded = false,
  });

  int get totalSizeBytes => items.fold<int>(0, (sum, item) => sum + item.sizeBytes);
  int get selectedSizeBytes =>
      items.where((i) => i.isChecked).fold<int>(0, (sum, item) => sum + item.sizeBytes);

  bool get isAllSelected => items.isNotEmpty && items.every((i) => i.isChecked);
  bool get isPartiallySelected =>
      items.any((i) => i.isChecked) && !items.every((i) => i.isChecked);

  CleanCategory copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    List<CleanItem>? items,
    bool? isExpanded,
  }) {
    return CleanCategory(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      items: items ?? this.items,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}
