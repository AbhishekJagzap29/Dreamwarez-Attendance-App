import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/models/task_request.dart';
import '/models/employee.dart';
import '/services/task_service.dart';
import '/services/employee_service.dart';
import '/widgets/search_filter_bar.dart';

class Task extends StatefulWidget {
  final List<String> groups;
  final String currentUserName;

  const Task({
    super.key,
    required this.groups,
    required this.currentUserName,
  });

  @override
  State<Task> createState() => _TaskState();
}

class _TaskState extends State<Task> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _showFilter = false;
  List<TaskRequest> _tasks = [];
  List<TaskRequest> _filteredTasks = [];
  String? _selectedFilterStatus = 'all';
  String? _tempFilterStatus = 'all';
  final TaskService _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _initialize();
    _searchController.addListener(_filterTasks);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterTasks);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      await _fetchTasks();
    } catch (e) {
      _showNotification('Initialization failed: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTasks() async {
    try {
      final isEmployeeOnly =
          widget.groups.contains('dm_employee.group_hr_employee') &&
              !widget.groups.contains('dm_employee.group_hr_admin') &&
              !widget.groups.contains('dm_employee.group_task_assigner');
      final tasks = await _taskService.fetchTasks(
        employeeName: isEmployeeOnly ? widget.currentUserName : null,
      );

      // Sort tasks: newest first (created tasks appear at top)
      tasks.sort((a, b) {
        return b.taskId.compareTo(a.taskId);
      });

      setState(() {
        _tasks = tasks;
        _filteredTasks = _tasks;
      });
    } catch (e) {
      _showNotification('Failed to load tasks: $e', isError: true);
    }
  }

  Future<void> _updateTaskState(int taskId, String newState) async {
    if (!widget.groups.contains('dm_employee.group_hr_employee')) {
      _showNotification('Only employees can update task status', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final backendState = newState.replaceAll(' ', '_').toLowerCase();
      await _taskService.updateTaskState(taskId, backendState);
      _showNotification('Task updated to $newState!');
      await _fetchTasks();
    } catch (e) {
      _showNotification('Failed to update task: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 2),
        content: Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 30.0, vertical: 14.0),
            constraints: const BoxConstraints(minWidth: 200.0),
            decoration: BoxDecoration(
              color: isError ? Colors.red : Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  void _filterTasks() {
    setState(() {
      final query = _searchController.text.trim().toLowerCase();
      var filtered = _tasks;

      if (_selectedFilterStatus != 'all') {
        filtered = filtered
            .where((task) => task.state?.toLowerCase() == _selectedFilterStatus)
            .toList();
      }

      if (query.isNotEmpty) {
        filtered = filtered
            .where((task) =>
                (task.assignedToName ?? '').toLowerCase().contains(query))
            .toList();
      }

      _filteredTasks = filtered;
    });
  }

  void _showFilterDialog() {
    setState(() {
      _showFilter = !_showFilter;
      _tempFilterStatus = _selectedFilterStatus;
    });
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty || date == 'N/A') return 'Not set';
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('dd-MM-yyyy').format(parsed);
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget _buildFilterUI() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF073850),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _tempFilterStatus == 'all',
                onSelected: (v) =>
                    setState(() => _tempFilterStatus = v ? 'all' : null),
              ),
              FilterChip(
                label: const Text('Pending'),
                selected: _tempFilterStatus == 'pending',
                avatar: CircleAvatar(backgroundColor: Colors.orange, radius: 8),
                onSelected: (v) =>
                    setState(() => _tempFilterStatus = v ? 'pending' : null),
              ),
              FilterChip(
                label: const Text('In Progress'),
                selected: _tempFilterStatus == 'in_progress',
                avatar: CircleAvatar(backgroundColor: Colors.blue, radius: 8),
                onSelected: (v) => setState(
                    () => _tempFilterStatus = v ? 'in_progress' : null),
              ),
              FilterChip(
                label: const Text('Done'),
                selected: _tempFilterStatus == 'done',
                avatar: CircleAvatar(backgroundColor: Colors.green, radius: 8),
                onSelected: (v) =>
                    setState(() => _tempFilterStatus = v ? 'done' : null),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFilterStatus = 'all';
                    _tempFilterStatus = 'all';
                    _showFilter = false;
                    _filterTasks();
                  });
                },
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedFilterStatus = _tempFilterStatus;
                    _showFilter = false;
                    _filterTasks();
                  });
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF073850)),
                child:
                    const Text('Apply', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskRequest task) {
    final displayState = task.formattedState(task.state ?? 'pending');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(
                task: task,
                groups: widget.groups,
                onUpdateStatus: (newState) {
                  _updateTaskState(task.taskId, newState);
                },
                currentUserName: widget.currentUserName,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF073850),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.state),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      displayState.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Assigned to: ${task.assignedToName ?? 'N/A'}',
                style: TextStyle(color: Colors.grey[700], fontSize: 15),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${formatDate(task.deadline)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Task Assignment',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF073850),
      ),
      floatingActionButton:
          widget.groups.contains('dm_employee.group_task_assigner') ||
                  widget.groups.contains('dm_employee.group_hr_admin')
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateTaskScreen(
                          groups: widget.groups,
                          currentUserName: widget.currentUserName,
                          onTaskCreated: () {
                            _fetchTasks(); // Refresh task list when returning
                          },
                        ),
                      ),
                    );
                  },
                  backgroundColor: const Color(0xFF073850),
                  child: const Icon(Icons.add, color: Colors.orange),
                )
              : null,
      body: Column(
        children: [
          if (_showFilter) _buildFilterUI(),
          SearchFilterBar(
            controller: _searchController,
            hintText: 'Search by assigned to...',
            showFilter: _showFilter,
            onChanged: _filterTasks,
            onFilterPressed: _showFilterDialog,
            padding: const EdgeInsets.all(8),
          ),
          _isLoading
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()))
              : _filteredTasks.isEmpty
                  ? const Expanded(
                      child: Center(child: Text('No tasks available')))
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = _filteredTasks[index];
                          return _buildTaskCard(task);
                        },
                      ),
                    ),
        ],
      ),
    );
  }
}

class CreateTaskScreen extends StatefulWidget {
  final List<String> groups;
  final String currentUserName;
  final VoidCallback onTaskCreated;

  const CreateTaskScreen({
    super.key,
    required this.groups,
    required this.currentUserName,
    required this.onTaskCreated,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  DateTime? startDate;
  DateTime? deadline;
  final TextEditingController _employeeController = TextEditingController();
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  List<Employee> _employees = [];
  String? _selectedEmployee;
  final TaskService _taskService = TaskService();
  final EmployeeService _employeeService = EmployeeService();

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  @override
  void dispose() {
    _employeeController.dispose();
    _taskNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    try {
      final employees = await _taskService.fetchAssignableEmployees();
      setState(() {
        _employees = employees;
      });
    } catch (e) {
      _showNotification('Failed to load employees: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) =>
          Theme(data: ThemeData.light(), child: child!),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          startDate = pickedDate;
        } else {
          deadline = pickedDate;
        }
      });
    }
  }

  Future<void> _submitTask() async {
    if (_selectedEmployee == null ||
        _taskNameController.text.isEmpty ||
        deadline == null) {
      _showNotification('Please fill all required fields', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selectedEmployee = _employees.firstWhere(
        (emp) => emp.id.toString() == _selectedEmployee,
        orElse: () => throw Exception('Selected employee not found'),
      );

      final task = TaskRequest(
        taskId: 0,
        employeeId: selectedEmployee.id.toString(),
        assignBy: widget.currentUserName,
        name: _taskNameController.text,
        startDate: startDate != null
            ? DateFormat('yyyy-MM-dd').format(startDate!)
            : null,
        endDate: null,
        deadline: DateFormat('yyyy-MM-dd').format(deadline!),
        description: _descriptionController.text,
        state: 'pending',
        assignedToName: selectedEmployee.name,
        assignedByName: widget.currentUserName,
      );

      await _taskService.createTask(task);
      _showNotification('Task created successfully!');

      // Clear form and go back
      _clearForm();
      widget.onTaskCreated();
      Navigator.pop(context);
    } catch (e) {
      _showNotification('You don\'t have access to create tasks',
          isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 2),
        content: Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 30.0, vertical: 14.0),
            constraints: const BoxConstraints(minWidth: 200.0),
            decoration: BoxDecoration(
              color: isError ? Colors.red : Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  void _clearForm() {
    _taskNameController.clear();
    _descriptionController.clear();
    setState(() {
      startDate = null;
      deadline = null;
      _selectedEmployee = null;
    });
  }

  Widget _buildEmployeeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Assigned To',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF073850))),
        const SizedBox(height: 8),
        IgnorePointer(
          ignoring: _isLoading || _employees.isEmpty,
          child: DropdownButtonFormField<String>(
            value: _selectedEmployee,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select employee',
              filled: true,
              fillColor: Colors.white,
            ),
            items: _employees
                .map((e) => DropdownMenuItem(
                    value: e.id.toString(), child: Text(e.name)))
                .toList(),
            onChanged: (v) => setState(() => _selectedEmployee = v),
          ),
        ),
        if (_isLoading) const LinearProgressIndicator(),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool multiline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF073850))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: multiline ? 3 : 1,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Enter ${label.toLowerCase()}',
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? date, bool isStartDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF073850))),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context, isStartDate),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date != null
                    ? DateFormat('dd-MM-yyyy').format(date)
                    : 'Select Date'),
                const Icon(Icons.calendar_today, color: Colors.blue),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create New Task',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF073850),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildEmployeeDropdown(),
            const SizedBox(height: 20),
            _buildTextField('Task Name', _taskNameController),
            const SizedBox(height: 20),
            _buildDateField('Start Date', startDate, true),
            const SizedBox(height: 20),
            _buildDateField('Deadline', deadline, false),
            const SizedBox(height: 20),
            _buildTextField('Description', _descriptionController,
                multiline: true),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _clearForm();
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF073850),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Create Task',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// TaskDetailScreen remains exactly the same as before
class TaskDetailScreen extends StatelessWidget {
  final TaskRequest task;
  final List<String> groups;
  final Function(String) onUpdateStatus;
  final String currentUserName;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.groups,
    required this.onUpdateStatus,
    required this.currentUserName,
  });

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty || date == 'N/A') return 'Not set';
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('dd-MM-yyyy').format(parsed);
    } catch (e) {
      return 'Invalid date';
    }
  }

  // Check if status transition is allowed
  bool _isStatusTransitionAllowed(String? currentStatus, String newStatus) {
    // Define allowed state transitions
    final allowedTransitions = {
      'pending': [
        'in_progress',
        'done'
      ], // Pending can go to In Progress or Done
      'in_progress': ['done'], // In Progress can only go to Done
      'done': [], // Done cannot go to any other state
    };

    final current = currentStatus ?? 'pending';
    final newState = newStatus.toLowerCase().replaceAll(' ', '_');

    return allowedTransitions[current]?.contains(newState) ?? false;
  }

  String _getStatusErrorMessage(String? currentStatus, String newStatus) {
    final current = currentStatus ?? 'pending';
    final newState = newStatus.toLowerCase().replaceAll(' ', '_');

    if (current == 'pending') {
      if (newState == 'pending') return 'Task is already in Pending state';
      return ''; // Allowed transitions
    } else if (current == 'in_progress') {
      if (newState == 'in_progress') return 'Task is already in Progress';
      if (newState == 'pending')
        return 'Cannot move task back to Pending once started';
      return ''; // Allowed to move to Done
    } else if (current == 'done') {
      if (newState == 'done') return 'Task is already completed';
      return 'Cannot update task once it is completed';
    }

    return 'Invalid status transition';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF073850),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[800], fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayState = task.formattedState(task.state ?? 'pending');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Task Details',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF073850),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF073850),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            task.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(task.state),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            displayState.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Task Details Card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Task Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF073850),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                              'Assigned To', task.assignedToName ?? 'N/A'),
                          const Divider(height: 24),
                          _buildDetailRow(
                              'Assigned By', task.assignedByName ?? 'N/A'),
                          const Divider(height: 24),
                          _buildDetailRow(
                              'Start Date', formatDate(task.startDate)),
                          const Divider(height: 24),
                          _buildDetailRow(
                              'Deadline', formatDate(task.deadline)),
                          const Divider(height: 24),
                          _buildDetailRow('End Date', formatDate(task.endDate)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description Card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF073850),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              task.description ?? 'No description provided',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Status Update Section - Fixed at bottom
          if (groups.contains('dm_employee.group_hr_employee'))
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF073850),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Pending Button - Only show if task is not started yet
                      if (task.state == 'pending')
                        _buildStatusButton(
                          label: 'Pending',
                          icon: Icons.access_time,
                          color: Colors.orange,
                          status: 'Pending',
                          isActive: task.state == 'pending',
                          isDisabled: !_isStatusTransitionAllowed(
                              task.state, 'Pending'),
                          onTap: () =>
                              _showStatusUpdateDialog(context, 'Pending'),
                        ),

                      // In Progress Button - Only allowed from Pending
                      if (_isStatusTransitionAllowed(task.state, 'In Progress'))
                        _buildStatusButton(
                          label: 'In Progress',
                          icon: Icons.play_circle_fill,
                          color: Colors.blue,
                          status: 'In Progress',
                          isActive: task.state == 'in_progress',
                          isDisabled: !_isStatusTransitionAllowed(
                              task.state, 'In Progress'),
                          onTap: () =>
                              _showStatusUpdateDialog(context, 'In Progress'),
                        ),

                      // Done Button - Allowed from Pending or In Progress
                      if (_isStatusTransitionAllowed(task.state, 'Done'))
                        _buildStatusButton(
                          label: 'Done',
                          icon: Icons.check_circle,
                          color: Colors.green,
                          status: 'Done',
                          isActive: task.state == 'done',
                          isDisabled:
                              !_isStatusTransitionAllowed(task.state, 'Done'),
                          onTap: () => _showStatusUpdateDialog(context, 'Done'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required String label,
    required IconData icon,
    required Color color,
    required String status,
    required bool isActive,
    required bool isDisabled,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: isActive
                ? color
                : (isDisabled ? Colors.grey[300] : color.withOpacity(0.1)),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? color
                  : (isDisabled ? Colors.grey[400]! : color.withOpacity(0.3)),
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: IconButton(
            onPressed: isDisabled ? null : onTap,
            icon: Icon(
              icon,
              size: 32,
              color: isActive
                  ? Colors.white
                  : (isDisabled ? Colors.grey[500] : color),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? color
                : (isDisabled ? Colors.grey[500] : Colors.grey[700]),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Current',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (isDisabled && !isActive)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Not Allowed',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  void _showStatusUpdateDialog(BuildContext context, String status) {
    final errorMessage = _getStatusErrorMessage(task.state, status);

    // If there's an error message, show error dialog
    if (errorMessage.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Cannot Update Status',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(errorMessage),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF073850),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // If status transition is allowed, show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          'Are you sure you want to Update "$status"',
          style: const TextStyle(fontSize: 16),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onUpdateStatus(status);
              Navigator.pop(context); // Go back to task list
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF073850),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Update',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
