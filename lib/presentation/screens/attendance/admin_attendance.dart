// lib/presentation/screens/attendance/admin_attendance.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/attendance.dart';
import '../../../data/repositories/attendance_repository.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen>
    with SingleTickerProviderStateMixin {
  final AttendanceRepository _attendanceRepo = AttendanceRepository();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _employees = [];
  List<Attendance> _todayAttendance = [];
  AttendanceSummary? _summary;
  DateTime _selectedDate = DateTime.now();
  String? _selectedEmployeeId;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('يرجى تسجيل الدخول أولاً');
      }

      final userData = await _supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();

      if (userData['role'] != 'admin') {
        throw Exception('⚠️ ليس لديك صلاحية للوصول إلى هذه الصفحة');
      }

      await Future.wait([
        _loadEmployees(),
        _loadTodayAttendance(),
        _loadSummary(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadEmployees() async {
    _employees = await _attendanceRepo.getEmployees();
  }

  Future<void> _loadTodayAttendance() async {
    _todayAttendance = await _attendanceRepo.getAttendanceByDate(
      date: _selectedDate,
      employeeId: _selectedEmployeeId,
    );
  }

  Future<void> _loadSummary() async {
    _summary = await _attendanceRepo.getAttendanceSummary(date: _selectedDate);
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  Future<void> _changeDate(DateTime newDate) async {
    setState(() {
      _selectedDate = newDate;
      _isLoading = true;
    });

    await Future.wait([_loadTodayAttendance(), _loadSummary()]);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _filterByEmployee(String? employeeId) async {
    setState(() {
      _selectedEmployeeId = employeeId;
      _isLoading = true;
    });

    await _loadTodayAttendance();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('لوحة تحكم الحضور'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '📊 الملخص'),
            Tab(text: '👥 الموظفين'),
            Tab(text: '📋 التقارير'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
            )
          : _errorMessage != null
          ? _buildErrorWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildEmployeesTab(),
                _buildReportsTab(),
              ],
            ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SUMMARY TAB ====================
  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDateSelector(),
          const SizedBox(height: 16),
          if (_summary != null) _buildSummaryCards(),
          const SizedBox(height: 16),
          _buildTodayAttendanceList(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE، d MMMM y', 'ar').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'اختر التاريخ لعرض البيانات',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  _changeDate(_selectedDate.subtract(const Duration(days: 1)));
                },
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    locale: const Locale('ar', 'EG'),
                  );
                  if (date != null) {
                    await _changeDate(date);
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  _changeDate(_selectedDate.add(const Duration(days: 1)));
                },
                icon: const Icon(Icons.arrow_forward_ios, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _SummaryCard(
          title: '✅ حاضر',
          count: _summary!.present,
          total: _summary!.totalEmployees,
          color: Colors.green,
          icon: Icons.check_circle,
        ),
        _SummaryCard(
          title: '⚠️ متأخر',
          count: _summary!.late,
          total: _summary!.totalEmployees,
          color: Colors.orange,
          icon: Icons.warning,
        ),
        _SummaryCard(
          title: '❌ غائب',
          count: _summary!.absent,
          total: _summary!.totalEmployees,
          color: Colors.red,
          icon: Icons.cancel,
        ),
        _SummaryCard(
          title: '📅 في إجازة',
          count: _summary!.onLeave,
          total: _summary!.totalEmployees,
          color: Colors.blue,
          icon: Icons.beach_access,
        ),
      ],
    );
  }

  Widget _buildTodayAttendanceList() {
    if (_todayAttendance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Column(
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'لا يوجد سجل حضور لهذا اليوم',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  '📋 سجل الحضور اليومي',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_todayAttendance.length} موظف',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _todayAttendance.length,
            separatorBuilder: (context, index) =>
                Divider(color: Colors.grey.shade200, height: 0),
            itemBuilder: (context, index) {
              final item = _todayAttendance[index];
              return _buildAttendanceListItem(item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceListItem(Attendance item) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: item.status.color.withValues(alpha: 0.1),
        child: Icon(item.status.icon, color: item.status.color, size: 20),
      ),
      title: Text(
        item.employeeName ?? 'موظف غير معروف',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${item.formattedCheckIn} ${item.isCheckedOut ? '→ ${item.formattedCheckOut}' : '(لم ينصرف بعد)'}',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: item.status.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          item.status.arabic,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: item.status.color,
          ),
        ),
      ),
      onTap: () {
        _showAttendanceDetails(item);
      },
    );
  }

  void _showAttendanceDetails(Attendance item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'تفاصيل الحضور',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: item.status.color,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('الموظف', item.employeeName ?? 'غير معروف'),
              _buildDetailRow('التاريخ', item.formattedDate),
              _buildDetailRow('وقت الحضور', item.formattedCheckIn),
              _buildDetailRow('وقت الانصراف', item.formattedCheckOut),
              _buildDetailRow('مدة العمل', item.formattedDuration),
              _buildDetailRow('الحالة', item.status.arabic),
              _buildDetailRow('الموقع', item.locationDisplay),
              if (item.notes != null && item.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'ملاحظات: ${item.notes}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ==================== EMPLOYEES TAB ====================
  Widget _buildEmployeesTab() {
    return Column(
      children: [
        // Filter
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: DropdownButtonFormField<String>(
            value: _selectedEmployeeId,
            hint: const Text('جميع الموظفين'),
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.people),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('جميع الموظفين'),
              ),
              ..._employees.map((employee) {
                return DropdownMenuItem<String>(
                  value: employee['id'],
                  child: Text(employee['name'] ?? 'موظف غير معروف'),
                );
              }),
            ],
            onChanged: (value) {
              _filterByEmployee(value);
            },
          ),
        ),

        const SizedBox(height: 8),

        // Employees List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _employees.length,
            itemBuilder: (context, index) {
              final employee = _employees[index];
              return _buildEmployeeCard(employee);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final employeeId = employee['id'];
    Attendance? todayRecord;

    try {
      todayRecord = _todayAttendance.firstWhere(
        (a) => a.employeeId == employeeId,
      );
    } catch (_) {
      todayRecord = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: employee['avatar_url'] != null
                ? NetworkImage(employee['avatar_url'])
                : null,
            backgroundColor: const Color(0xFF2563EB),
            child: employee['avatar_url'] == null
                ? Text(
                    (employee['name'] ?? 'م')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee['name'] ?? 'موظف غير معروف',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  employee['email'] ?? '',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (todayRecord != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: todayRecord.status.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                todayRecord.status.arabic,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: todayRecord.status.color,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'غائب',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== REPORTS TAB ====================
  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDateSelector(),
          const SizedBox(height: 16),
          if (_summary != null) _buildSummaryCards(),
          const SizedBox(height: 16),
          _buildStatisticsCard(),
          const SizedBox(height: 16),
          _buildExportButtons(),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    if (_summary == null) return const SizedBox.shrink();

    final attendanceRate = _summary!.totalEmployees > 0
        ? (_summary!.present / _summary!.totalEmployees) * 100
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 الإحصائيات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'نسبة الحضور',
                  '${attendanceRate.toStringAsFixed(1)}%',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'إجمالي الموظفين',
                  '${_summary!.totalEmployees}',
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'الحضور اليوم',
                  '${_summary!.present}',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'الغياب اليوم',
                  '${_summary!.absent}',
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('جاري إنشاء التقرير...'),
                  backgroundColor: Color(0xFF2563EB),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text(
              'تصدير تقرير PDF',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('جاري تصدير البيانات...'),
                  backgroundColor: Color(0xFF2563EB),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF2563EB)),
              foregroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.table_chart),
            label: const Text(
              'تصدير Excel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== SUMMARY CARD WIDGET ====================
class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final int total;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(
            'من $total موظف',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
