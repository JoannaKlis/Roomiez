// Prosty model reprezentujący zadanie do wykonania
class Task {
  final String id;
  final String title;
  final String assignedTo; // Kto jest przypisany (np. "Ana", "Martin")
  bool isDone; // Status "zrobione" lub "niezrobione"
  final String dueDate; // Np. "Tomorrow", "31.10.2025"

  Task({
    required this.id,
    required this.title,
    required this.assignedTo,
    required this.isDone,
    required this.dueDate,
  });
}