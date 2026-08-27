class OwnerLifecycle {
  final Map<String, int> _generations = {};

  int generation(String ownerStudentId) => _generations[ownerStudentId] ?? 0;

  bool isCurrent(String ownerStudentId, int generation) =>
      this.generation(ownerStudentId) == generation;

  void invalidate(String ownerStudentId) {
    _generations[ownerStudentId] = generation(ownerStudentId) + 1;
  }
}
