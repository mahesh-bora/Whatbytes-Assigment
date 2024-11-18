import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/tasks.dart';
import '../presentation/widgets/task_form.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    final userId = Provider.of<AuthProvider>(context, listen: false).user!.uid;
    Provider.of<TaskProvider>(context, listen: false).loadTasks(userId);

    _tabController = TabController(length: 3, vsync: this);
    _searchController = TextEditingController();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimationController.forward();

    _tabController.addListener(() {
      setState(() {
        if (_tabController.index == 2) {
          // Completed tasks tab
          _fabAnimationController.reverse();
        } else {
          _fabAnimationController.forward();
        }
      }); // Rebuild to update FAB visibility
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _openTaskForm({Task? task}) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskForm(task: task),
    );
  }

  void _toggleTaskCompletion(Task task) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final updatedTask = Task(
      id: task.id,
      userId: task.userId,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      priority: task.priority,
      isCompleted: !task.isCompleted,
    );

    try {
      await taskProvider.updateTask(updatedTask);
      HapticFeedback.lightImpact();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Task> _getFilteredTasks(List<Task> tasks) {
    final searchTerm = _searchController.text.toLowerCase();
    var filteredTasks = tasks.where((task) {
      final matchesSearch = task.title.toLowerCase().contains(searchTerm) ||
          task.description.toLowerCase().contains(searchTerm);

      switch (_tabController.index) {
        case 1: // In Progress
          return !task.isCompleted && matchesSearch;
        case 2: // Completed
          return task.isCompleted && matchesSearch;
        default: // All
          return matchesSearch;
      }
    }).toList();

    return filteredTasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Tasks',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            Consumer<TaskProvider>(
              builder: (context, taskProvider, _) {
                final totalTasks = taskProvider.tasks.length;
                final completedTasks =
                    taskProvider.tasks.where((task) => task.isCompleted).length;
                return Text(
                  '$completedTasks/$totalTasks tasks completed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                );
              },
            ),
          ],
        ),
        actions: [
          // Filter Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton<TaskPriority?>(
              icon: Icon(Icons.filter_list,
                  color: Theme.of(context).primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              position: PopupMenuPosition.under,
              onSelected: (priority) {
                HapticFeedback.selectionClick();
                Provider.of<TaskProvider>(context, listen: false)
                    .setFilters(priority: priority);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('All Tasks'),
                ),
                ...TaskPriority.values.map(
                  (priority) => PopupMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: priority == TaskPriority.high
                              ? Colors.red
                              : priority == TaskPriority.medium
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(priority.toString().split('.').last),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Profile Button
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.person_outline),
              color: Theme.of(context).primaryColor,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) => _buildProfileSheet(),
                );
              },
            ),
          ),
        ],
      ),
      // floatingActionButton: _tabController.index != 2
      //     ? Padding(
      //         padding: const EdgeInsets.only(right: 12),
      //         child: Row(
      //           mainAxisAlignment: MainAxisAlignment.end,
      //           children: [
      //             // Primary FAB
      //             ScaleTransition(
      //               scale: _fabAnimationController,
      //               child: FloatingActionButton(
      //                 heroTag: 'createTask',
      //                 onPressed: () => _openTaskForm(),
      //                 backgroundColor: Theme.of(context).primaryColor,
      //                 child: const Icon(Icons.add),
      //                 elevation: 4,
      //               ),
      //             ),
      //             const SizedBox(width: 16),
      //             // Secondary FAB
      //             ScaleTransition(
      //               scale: _fabAnimationController,
      //               child: FloatingActionButton.extended(
      //                 heroTag: 'quickTask',
      //                 onPressed: () => _openTaskForm(),
      //                 backgroundColor:
      //                     Theme.of(context).primaryColor.withOpacity(0.9),
      //                 icon: const Icon(Icons.add),
      //                 label: const Text('Quick Task'),
      //                 elevation: 4,
      //               ),
      //             ),
      //           ],
      //         ),
      //       )
      //     : null,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: 'quickTask',
              onPressed: () => _openTaskForm(),
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.5),
              icon: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              label: const Text(
                'Quick Task',
                style: TextStyle(color: Colors.white),
              ),
              elevation: 4,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon:
                    Icon(Icons.search, color: Theme.of(context).primaryColor),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[400]),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Task Categories
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey[400],
            indicatorColor: Theme.of(context).primaryColor,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'In Progress'),
              Tab(text: 'Completed'),
            ],
          ),

          // Task List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(filterCompleted: null),
                _buildTaskList(filterCompleted: false),
                _buildTaskList(filterCompleted: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList({bool? filterCompleted}) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        var tasks = taskProvider.tasks;
        if (filterCompleted != null) {
          tasks = tasks
              .where((task) => task.isCompleted == filterCompleted)
              .toList();
        }
        tasks = _getFilteredTasks(tasks);

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  filterCompleted == true
                      ? Icons.task_alt
                      : Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  filterCompleted == true
                      ? 'No completed tasks yet'
                      : filterCompleted == false
                          ? 'No tasks in progress'
                          : 'No tasks found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Dismissible(
              key: Key(task.id),
              background: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerLeft,
                child: const Icon(Icons.check, color: Colors.white),
              ),
              secondaryBackground: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) {
                if (direction == DismissDirection.endToStart) {
                  taskProvider.deleteTask(task.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Task deleted'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          taskProvider.addTask(task);
                        },
                      ),
                    ),
                  );
                } else {
                  _toggleTaskCompletion(task);
                }
              },
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  onTap: () => _openTaskForm(task: task),
                  leading: IconButton(
                    icon: Icon(
                      task.isCompleted
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: task.isCompleted ? Colors.green : Colors.grey,
                    ),
                    onPressed: () => _toggleTaskCompletion(task),
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: task.priority == TaskPriority.high
                              ? Colors.red[100]
                              : task.priority == TaskPriority.medium
                                  ? Colors.orange[100]
                                  : Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          task.priority.toString().split('.').last,
                          style: TextStyle(
                            fontSize: 12,
                            color: task.priority == TaskPriority.high
                                ? Colors.red[900]
                                : task.priority == TaskPriority.medium
                                    ? Colors.orange[900]
                                    : Colors.green[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileSheet() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.email ?? 'User',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              // Implement settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () {
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
          ),
        ],
      ),
    );
  }
}
