# FocusByte - Complete Task Management Feature

## Overview

FocusByte is a minimalist Pomodoro timer app with an integrated, professional task management system. This feature set includes CRUD operations, date/time scheduling, reminders, and task reset functionality.

## Files Created

### 1. **models/task_model.dart**

- `Task` class with full properties: id, title, date, time, reminder, isCompleted, createdAt
- `copyWith()` method for immutable updates
- `toJson()` and `fromJson()` for serialization

### 2. **providers/task_provider.dart**

- Riverpod `TaskNotifier` and `StateNotifierProvider` for state management
- CRUD operations: `addTask()`, `updateTask()`, `deleteTask()`, `resetTask()`
- Helper methods: `toggleTaskCompletion()`, `getTaskById()`, `getAllTasks()`, `getCompletedTasks()`, `getIncompleteTasks()`
- Automatic persistence with SharedPreferences
- Family providers for filtering tasks

### 3. **widgets/task_tile.dart**

- `TaskTile` widget displaying individual tasks in a list
- Shows title, date/time, and completion status
- Swipe-to-delete gesture with undo support
- Popup menu with Edit, Reset, and Delete actions
- Professional styling with dark/light mode support

### 4. **widgets/task_form_sheet.dart**

- `TaskFormSheet` bottom sheet for adding and editing tasks
- Form fields: title, date picker, time picker, reminder picker
- Validation and error handling
- Supports both create and update workflows
- Clean, intuitive UI with visual feedback

### 5. **Updated pubspec.yaml**

- Added `flutter_riverpod: ^2.4.0` for state management
- Added `uuid: ^4.0.0` for unique task IDs

### 6. **Updated main.dart**

- Wrapped app with `ProviderScope` for Riverpod
- Integrated `Consumer` widget to watch task list
- Removed old Task class and task management logic
- Uses new `TaskTile` and `TaskFormSheet` components
- Maintains existing Pomodoro timer functionality

## Feature List

### Task Properties

- **id**: Unique identifier (UUID v4)
- **title**: Task name/description
- **date**: Scheduled date
- **time**: Scheduled time (TimeOfDay)
- **reminder**: Optional reminder datetime
- **isCompleted**: Completion status flag
- **createdAt**: Task creation timestamp

### Operations

#### Create Task

```dart
final task = Task(
  title: 'Complete project',
  date: DateTime.now(),
  time: const TimeOfDay(hour: 14, minute: 30),
  reminder: DateTime.now().add(Duration(hours: 1)),
);
ref.read(taskProvider.notifier).addTask(task);
```

#### Update Task

```dart
final updated = existingTask.copyWith(
  title: 'Updated title',
  time: const TimeOfDay(hour: 15, minute: 0),
);
ref.read(taskProvider.notifier).updateTask(updated);
```

#### Delete Task

```dart
ref.read(taskProvider.notifier).deleteTask(taskId);
```

#### Reset Task

```dart
// Sets isCompleted back to false
ref.read(taskProvider.notifier).resetTask(taskId);
```

#### Toggle Completion

```dart
ref.read(taskProvider.notifier).toggleTaskCompletion(taskId);
```

## UI/UX Features

### Task Tile

- Checkbox to toggle completion
- Task title with strikethrough when completed
- Date and time display (formats "Today", "Tomorrow", or "Dec 25")
- Popup menu for actions
- Swipe-to-delete with undo capability
- Modern styling with transparency and gradients

### Task Form

- Beautiful bottom sheet interface
- Title input field (supports multi-line)
- Date picker with quick select (Today, Tomorrow)
- Time picker with visual display
- Optional reminder date picker
- Cancel and Save/Update buttons
- Field validation with user feedback

### Color Scheme

- Primary: `#60A5FA` (Blue)
- Secondary: `#94A3B8` (Slate)
- Background: `#0F1724` (Dark blue-gray)
- Accent: `#1A2847` (Navy)

## State Management (Riverpod)

### Providers

```dart
// Main task list
final taskProvider = StateNotifierProvider<TaskNotifier, List<Task>>

// Filtered lists
final completedTasksProvider = Provider<List<Task>>
final incompleteTasksProvider = Provider<List<Task>>

// Single task lookup
final taskByIdProvider = Provider.family<Task?, String>
```

## Data Persistence

- All tasks are automatically saved to `SharedPreferences`
- Tasks persist across app restarts
- Serialization via `toJson()` and `fromJson()` methods

## Integration with FocusByte

The task management feature integrates seamlessly with the Pomodoro timer:

- Both features coexist in the same UI
- Separate state management (timer state vs. task state)
- Users can set focus timers while managing their task list
- Individual task timing/scheduling for productivity workflows

## How to Use

### Adding a Task

1. Tap the **+** button next to the quick-add input field
2. Fill in task details in the bottom sheet
3. Tap **Add** to create the task

### Editing a Task

1. Tap the **menu icon** (⋮) on a task
2. Select **Edit**
3. Modify details in the form
4. Tap **Update** to save

### Completing a Task

- Click the **checkbox** next to the task title

### Resetting a Task

1. Tap the **menu icon** (⋮)
2. Select **Reset** (only visible for completed tasks)

### Deleting a Task

- **Swipe left** on the task, or
- Tap the **menu icon** (⋮) and select **Delete**
- Use the **Undo** button to restore

## Code Quality

- **Comments**: Detailed explanations throughout
- **Error Handling**: Validation and user feedback
- **Responsive Design**: Adapts to phone/tablet screens
- **Dark Mode Support**: Automatic light/dark theme colors
- **Immutability**: Uses `copyWith()` for safe state updates
- **Separation of Concerns**: Models, providers, and widgets properly organized

---

**Version**: 1.0.0  
**Framework**: Flutter + Riverpod  
**Architecture**: MVVM with Provider pattern  
**Tested on**: Flutter 3.41.9
