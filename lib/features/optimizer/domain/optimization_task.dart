class OptimizationTask {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final bool isRunning;
  final bool isCompleted;

  const OptimizationTask({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    this.isRunning = false,
    this.isCompleted = false,
  });

  OptimizationTask copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    bool? isRunning,
    bool? isCompleted,
  }) {
    return OptimizationTask(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      isRunning: isRunning ?? this.isRunning,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
