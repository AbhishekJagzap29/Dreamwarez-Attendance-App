import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '/services/employee_service.dart';
import '/services/payslip_service.dart';
import '/models/employee.dart';
import '/models/payslip.dart';
import 'dart:developer' as developer;

class PayslipPage extends StatefulWidget {
  const PayslipPage({super.key});

  @override
  State<PayslipPage> createState() => _PayslipPageState();
}

class _PayslipPageState extends State<PayslipPage> {
  final EmployeeService _employeeService = EmployeeService();
  final PayslipService _payslipService = PayslipService();
  List<Employee> _employees = [];
  List<Payslip> _payslips = [];
  List<Map<String, dynamic>> _contracts = [];
  String? _selectedEmployeeName;
  int? _selectedEmployeeId;
  int? _selectedContractId;
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  final TextEditingController _salaryStructureController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime _focusedDay = DateTime.now();
  bool _isFormOpen = false;
  bool _isLoading = true;
  bool _isContractsLoading = false;
  final Map<int, Payslip?> _detailedPayslips = {};
  final Map<int, bool> _isDetailLoading = {};

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    _fetchPayslips();
  }

  Future<void> _fetchEmployees() async {
    try {
      developer.log('Fetching employees', name: 'PayslipPage');
      final employees = await _employeeService.getEmployees();
      setState(() {
        _employees = employees;
      });
      developer.log(
          'Employees fetched successfully, count: ${employees.length}',
          name: 'PayslipPage');
    } catch (e) {
      developer.log('Failed to fetch employees: $e',
          name: 'PayslipPage', error: e);
      _showSnackBar('Failed to fetch employees: $e');
    }
  }

  Future<void> _fetchPayslips() async {
    try {
      developer.log('Fetching payslips', name: 'PayslipPage');
      final payslips = await _payslipService.fetchPayslips();
      setState(() {
        _payslips = payslips;
        _isLoading = false;
      });
      developer.log('Payslips fetched successfully, count: ${payslips.length}',
          name: 'PayslipPage');
    } catch (e) {
      developer.log('Failed to fetch payslips: $e',
          name: 'PayslipPage', error: e);
      _showSnackBar('Failed to fetch payslips: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPayslipDetails(int id) async {
    if (_detailedPayslips.containsKey(id) && _detailedPayslips[id] != null) {
      developer.log('Payslip details for ID: $id already cached',
          name: 'PayslipPage');
      return;
    }

    setState(() {
      _isDetailLoading[id] = true;
    });
    developer.log('Fetching payslip details for ID: $id', name: 'PayslipPage');

    try {
      final detailedPayslip = await _payslipService.fetchPayslipDetails(id);
      setState(() {
        _detailedPayslips[id] = detailedPayslip;
        _isDetailLoading[id] = false;
      });
      developer.log('Payslip details fetched successfully for ID: $id',
          name: 'PayslipPage');
    } catch (e) {
      setState(() {
        _isDetailLoading[id] = false;
      });
      developer.log('Failed to fetch payslip details: $e',
          name: 'PayslipPage', error: e);
      _showSnackBar('Failed to fetch payslip details: $e');
    }
  }

  Future<void> _fetchContracts(int employeeId) async {
    setState(() {
      _isContractsLoading = true;
      _contracts = [];
      _selectedContractId = null;
    });
    developer.log('Fetching contracts for employee ID: $employeeId',
        name: 'PayslipPage');

    try {
      final contracts = await _payslipService.fetchContracts(employeeId);
      final filteredContracts = contracts.where((contract) {
        final contractEmployeeId = contract['employee_id'] is Map
            ? contract['employee_id']['id']
            : contract['employee_id'] is int
                ? contract['employee_id']
                : null;
        final contractEmployeeName = contract['employee_name'] ?? '';
        return contractEmployeeId == employeeId ||
            contractEmployeeName == _selectedEmployeeName;
      }).toList();

      setState(() {
        _contracts = filteredContracts;
        _isContractsLoading = false;

        if (_contracts.isNotEmpty) {
          final preferredContract = _contracts.firstWhere(
            (c) => (c['name'] ?? '').contains(_selectedEmployeeName ?? ''),
            orElse: () => _contracts.first,
          );
          _selectedContractId = preferredContract['id'] as int;
        }
      });
      developer.log(
          'Contracts fetched successfully, count: ${filteredContracts.length}',
          name: 'PayslipPage');
    } catch (e) {
      setState(() {
        _isContractsLoading = false;
      });
      developer.log('Failed to fetch contracts: $e',
          name: 'PayslipPage', error: e);
      _showSnackBar('Failed to fetch contracts: $e');
    }
  }

  void _showSnackBar(String msg, {Color color = Colors.green}) {
    developer.log('Showing SnackBar: $msg', name: 'PayslipPage');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _clearForm() {
    setState(() {
      _selectedEmployeeName = null;
      _selectedEmployeeId = null;
      _selectedContractId = null;
      _contracts = [];
      _selectedDateFrom = null;
      _selectedDateTo = null;
      _dateFromController.clear();
      _dateToController.clear();
      _salaryStructureController.clear();
      _isFormOpen = false;
    });
    developer.log('Form cleared', name: 'PayslipPage');
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final newPayslip = await _payslipService.createPayslip(
        employeeId: _selectedEmployeeId!,
        dateFrom: _selectedDateFrom!,
        dateTo: _selectedDateTo!,
        contractId: _selectedContractId!,
      );

      setState(() {
        _payslips.insert(0, newPayslip);

        // ✅ CLOSE FORM
        _isFormOpen = false;

        // optional reset fields
        _selectedEmployeeName = null;
        _selectedEmployeeId = null;
        _selectedContractId = null;
        _contracts = [];
        _selectedDateFrom = null;
        _selectedDateTo = null;
        _dateFromController.clear();
        _dateToController.clear();
        _salaryStructureController.clear();
      });

      _showSnackBar(
        'Payslip created successfully',
        color: Colors.green,
      );
    } catch (e) {
      _showSnackBar('Error creating payslip', color: Colors.red);
    }
  }

  Future<void> _showCalendarDialog({required bool isFromDate}) async {
    DateTime? tempSelectedDate =
        isFromDate ? _selectedDateFrom : _selectedDateTo;
    DateTime tempFocusedDay = tempSelectedDate ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Select ${isFromDate ? 'From' : 'To'} Date',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color.fromARGB(255, 7, 56, 80),
                          ),
                    ),
                    const SizedBox(height: 16),

                    /// 📅 Calendar
                    TableCalendar(
                      firstDay: DateTime(2000),
                      lastDay: DateTime(2100),
                      focusedDay: tempFocusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(tempSelectedDate, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setDialogState(() {
                          tempSelectedDate = selectedDay;
                          tempFocusedDay = focusedDay;
                        });
                      },
                      calendarFormat: CalendarFormat.month,
                      headerStyle: const HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                      ),
                      calendarStyle: CalendarStyle(
                        selectedDecoration: const BoxDecoration(
                          color: Color.fromARGB(255, 7, 56, 80),
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: TextStyle(color: Colors.white),
                        todayDecoration: BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            if (tempSelectedDate != null) {
                              setState(() {
                                if (isFromDate) {
                                  _selectedDateFrom = tempSelectedDate;
                                  _dateFromController.text =
                                      DateFormat('dd-MM-yyyy')
                                          .format(tempSelectedDate!);
                                } else {
                                  _selectedDateTo = tempSelectedDate;
                                  _dateToController.text =
                                      DateFormat('dd-MM-yyyy')
                                          .format(tempSelectedDate!);
                                }
                              });
                            }
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 7, 56, 80),
                          ),
                          child: const Text('Confirm'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color.fromARGB(255, 7, 56, 80), width: 2),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
                color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 7, 56, 80),
                ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dateFromController.dispose();
    _dateToController.dispose();
    _salaryStructureController.dispose();
    super.dispose();
    developer.log('PayslipPage disposed', name: 'PayslipPage');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payslips',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isFormOpen
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Create New Payslip",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color.fromARGB(255, 7, 56, 80),
                                  ),
                            ),
                            const SizedBox(height: 24),
                            _buildFormField(
                              label: 'Employee Name',
                              child: DropdownButtonFormField<String>(
                                value: _selectedEmployeeName,
                                decoration: _inputDecoration(
                                    hintText: 'Select employee'),
                                items: _employees
                                    .map((e) => DropdownMenuItem(
                                          value: e.name,
                                          child: Text(e.name),
                                        ))
                                    .toList(),
                                onChanged: (val) async {
                                  final selectedEmployee = _employees
                                      .firstWhere((e) => e.name == val);
                                  setState(() {
                                    _selectedEmployeeName = val;
                                    _selectedEmployeeId = selectedEmployee.id;
                                    _selectedContractId = null;
                                    _contracts = [];
                                  });
                                  developer.log(
                                    'Selected employee: $val, ID: ${selectedEmployee.id}',
                                    name: 'PayslipPage',
                                  );
                                  await _fetchContracts(selectedEmployee.id);
                                },
                                validator: (val) => val == null
                                    ? 'Please select an employee'
                                    : null,
                              ),
                            ),
                            _buildFormField(
                              label: 'Contract',
                              child: _isContractsLoading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : DropdownButtonFormField<int>(
                                      value: _selectedContractId,
                                      decoration: _inputDecoration(
                                          hintText: _contracts.isEmpty
                                              ? 'No contracts available'
                                              : 'Select contract'),
                                      items: _contracts.isEmpty
                                          ? [
                                              const DropdownMenuItem<int>(
                                                value: null,
                                                enabled: false,
                                                child: Text(
                                                  'No contracts available',
                                                  style: TextStyle(
                                                      color: Colors.grey),
                                                ),
                                              )
                                            ]
                                          : _contracts
                                              .map((c) => DropdownMenuItem<int>(
                                                    value: c['id'] as int,
                                                    child: Text(c['name'] ??
                                                        'Contract ${c['id']}'),
                                                  ))
                                              .toList(),
                                      onChanged: (val) {
                                        setState(
                                            () => _selectedContractId = val);
                                        developer.log(
                                          'Selected contract ID: $val',
                                          name: 'PayslipPage',
                                        );
                                      },
                                      validator: (val) => val == null
                                          ? 'Please select a contract'
                                          : null,
                                    ),
                            ),
                            _buildFormField(
                              label: 'Payslip From Date',
                              child: TextFormField(
                                controller: _dateFromController,
                                readOnly: true,
                                onTap: () =>
                                    _showCalendarDialog(isFromDate: true),
                                decoration: _inputDecoration(
                                  hintText: 'Select from date',
                                  suffixIcon: const Icon(Icons.calendar_today,
                                      size: 20),
                                ),
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Select a from date'
                                    : null,
                              ),
                            ),
                            _buildFormField(
                              label: 'Payslip To Date',
                              child: TextFormField(
                                controller: _dateToController,
                                readOnly: true,
                                onTap: () =>
                                    _showCalendarDialog(isFromDate: false),
                                decoration: _inputDecoration(
                                  hintText: 'Select to date',
                                  suffixIcon: const Icon(Icons.calendar_today,
                                      size: 20),
                                ),
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Select a to date'
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: _clearForm,
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    side: const BorderSide(color: Colors.grey),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 7, 56, 80),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                  ),
                                  child: const Text(
                                    'Create Payslip',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: _payslips.isEmpty
                      ? Center(
                          child: Text(
                            'No payslips available',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _payslips.length,
                          itemBuilder: (context, index) {
                            final p = _payslips[index];
                            final loading = _isDetailLoading[p.id] ?? false;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                title: Text(
                                  p.employeeName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: const Color.fromARGB(
                                            255, 7, 56, 80),
                                      ),
                                ),
                                subtitle: Text(
                                  'From: ${p.dateFrom != null ? DateFormat('dd-MM-yyyy').format(p.dateFrom!) : 'N/A'} '
                                  'To: ${p.dateTo != null ? DateFormat('dd-MM-yyyy').format(p.dateTo!) : 'N/A'}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                onTap: loading
                                    ? null
                                    : () async {
                                        developer.log(
                                          'Tapped payslip: ID=${p.id}, Employee=${p.employeeName}',
                                          name: 'PayslipPage',
                                        );
                                        await _fetchPayslipDetails(p.id);
                                        if (_detailedPayslips[p.id] != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PayslipDetailsPage(
                                                payslip:
                                                    _detailedPayslips[p.id]!,
                                                onCompute: (newLines) {
                                                  setState(() {
                                                    _payslips = _payslips
                                                        .map((payslip) => payslip.id == p.id
                                                            ? Payslip(
                                                                id: payslip.id,
                                                                name: payslip
                                                                    .name,
                                                                number: payslip
                                                                    .number,
                                                                employeeName: payslip
                                                                    .employeeName,
                                                                state: payslip
                                                                    .state,
                                                                dateFrom: payslip
                                                                    .dateFrom,
                                                                dateTo: payslip
                                                                    .dateTo,
                                                                employeeId: payslip
                                                                    .employeeId,
                                                                structId: payslip
                                                                    .structId,
                                                                contractId: payslip
                                                                    .contractId,
                                                                companyId: payslip
                                                                    .companyId,
                                                                paid: payslip
                                                                    .paid,
                                                                note: payslip
                                                                    .note,
                                                                creditNote: payslip
                                                                    .creditNote,
                                                                payslipRunId: payslip
                                                                    .payslipRunId,
                                                                workedDaysLineIds:
                                                                    payslip.workedDaysLineIds,
                                                                inputLineIds: payslip.inputLineIds,
                                                                lineIds: newLines)
                                                            : payslip)
                                                        .toList();
                                                    _detailedPayslips[p.id] =
                                                        Payslip(
                                                      id: p.id,
                                                      name: p.name,
                                                      number: p.number,
                                                      employeeName:
                                                          p.employeeName,
                                                      state: p.state,
                                                      dateFrom: p.dateFrom,
                                                      dateTo: p.dateTo,
                                                      employeeId: p.employeeId,
                                                      structId: p.structId,
                                                      contractId: p.contractId,
                                                      companyId: p.companyId,
                                                      paid: p.paid,
                                                      note: p.note,
                                                      creditNote: p.creditNote,
                                                      payslipRunId:
                                                          p.payslipRunId,
                                                      workedDaysLineIds:
                                                          p.workedDaysLineIds,
                                                      inputLineIds:
                                                          p.inputLineIds,
                                                      lineIds: newLines,
                                                    );
                                                  });
                                                  developer.log(
                                                    'Updated payslip lines for ID: ${p.id}, New lines: ${newLines.length}',
                                                    name: 'PayslipPage',
                                                  );
                                                },
                                                onConfirm: () async {
                                                  try {
                                                    // 1️⃣ CONFIRM payslip on server (WRITE)
                                                    // await _payslipService
                                                    //     .confirmPayslip(p.id);

                                                    // 2️⃣ FETCH updated payslip (READ)
                                                    final updatedPayslip =
                                                        await _payslipService
                                                            .fetchPayslipDetails(
                                                                p.id);

                                                    // 3️⃣ UPDATE UI STATE
                                                    setState(() {
                                                      _payslips = _payslips
                                                          .map((ps) => ps.id ==
                                                                  p.id
                                                              ? updatedPayslip
                                                              : ps)
                                                          .toList();

                                                      _detailedPayslips[p.id] =
                                                          updatedPayslip;
                                                    });

                                                    developer.log(
                                                      'Payslip confirmed & refreshed: ID=${p.id}, State=${updatedPayslip.state}',
                                                      name: 'PayslipPage',
                                                    );
                                                  } catch (e) {
                                                    _showSnackBar(
                                                        'Failed to confirm payslip');
                                                  }
                                                },
                                              ),
                                            ),
                                          );
                                        }
                                      },
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() => _isFormOpen = true);
          developer.log('Opening payslip creation form', name: 'PayslipPage');
        },
        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class PayslipDetailsPage extends StatefulWidget {
  final Payslip payslip;
  final Function(List<Map<String, dynamic>>) onCompute;
  final VoidCallback onConfirm;

  const PayslipDetailsPage({
    super.key,
    required this.payslip,
    required this.onCompute,
    required this.onConfirm,
  });

  @override
  State<PayslipDetailsPage> createState() => _PayslipDetailsPageState();
}

class _PayslipDetailsPageState extends State<PayslipDetailsPage> {
  final PayslipService _payslipService = PayslipService();
  bool _isComputing = false;
  bool _isConfirming = false;
  late Payslip _payslip;

  @override
  void initState() {
    super.initState();
    _payslip = widget.payslip; // ✅ REQUIRED
  }

  Future<void> _computeSheet() async {
    if (_payslip.state != 'draft' && _payslip.state != 'verify') {
      _showSnackBar('Payslip must be in Draft or Waiting state');
      return;
    }

    setState(() => _isComputing = true);

    try {
      // 1️⃣ Compute on server
      await _payslipService.computePayslipSheet(_payslip.id);

      // 2️⃣ Fetch updated payslip
      final updatedPayslip =
          await _payslipService.fetchPayslipDetails(_payslip.id);

      // 3️⃣ Update UI
      setState(() {
        _payslip = updatedPayslip;
      });

      // 4️⃣ Sync parent list
      widget.onCompute(updatedPayslip.lineIds);

      _showSnackBar('Payslip computed successfully', color: Colors.green);
    } catch (e) {
      _showSnackBar(e.toString());
    } finally {
      setState(() => _isComputing = false);
    }
  }

  Future<void> _confirmPayslip() async {
    // 🔒 HARD BLOCK
    if (_isConfirming) return;

    if (_payslip.state != 'draft' && _payslip.state != 'verify') {
      _showSnackBar(
        'Payslip must be in Draft or Waiting state to confirm',
        color: Colors.orange,
      );
      return;
    }

    setState(() => _isConfirming = true);

    try {
      await _payslipService.confirmPayslip(_payslip.id);

      widget.onConfirm();
      Navigator.pop(context);

      developer.log(
        'Payslip confirmed successfully: ID=${_payslip.id}',
        name: 'PayslipDetailsPage',
      );
    } catch (e) {
      developer.log(
        'Error confirming payslip: $e',
        name: 'PayslipDetailsPage',
        error: e,
      );
      _showSnackBar('Failed to confirm payslip');
    } finally {
      _isConfirming = false; // 👈 DO NOT setState here
    }
  }

  void _showSnackBar(String msg, {Color color = Colors.red}) {
    developer.log('Showing SnackBar: $msg', name: 'PayslipDetailsPage');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
                color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payslip: ${_payslip.employeeName}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Payslip Number', _payslip.number),
                // _buildDetailRow('State', _payslip.state),
                _buildDetailRow(
                  'State',
                  _payslip.state.isNotEmpty
                      ? _payslip.state[0].toUpperCase() +
                          _payslip.state.substring(1)
                      : '',
                ),

                _buildDetailRow(
                    'Note', _payslip.note.isEmpty ? 'N/A' : _payslip.note),
                _buildDetailRow('Paid', _payslip.paid ? 'Yes' : 'No'),
                _buildDetailRow(
                    'Credit Note', _payslip.creditNote ? 'Yes' : 'No'),
                const SizedBox(height: 16),
                Text(
                  'Salary Lines',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color.fromARGB(255, 7, 56, 80),
                      ),
                ),
                const SizedBox(height: 8),
                ..._payslip.lineIds.map((line) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                line['name'] ?? 'N/A',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '₹${(line['amount'] ?? 0.0).toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [],
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [],
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: _isComputing ? null : _computeSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: _isComputing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Compute Sheet',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: (_isConfirming || _payslip.state == 'done')
                          ? null
                          : _confirmPayslip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: _isConfirming
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Confirm Payslip',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
