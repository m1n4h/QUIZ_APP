import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_app/constants/app_styles.dart';
import 'package:quiz_app/models/quiz_model.dart';
import 'package:quiz_app/services/api_service.dart';
import 'package:quiz_app/screens/profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = Get.find<ApiService>();
  late TabController _tabController;
  List<Quiz> _allQuizzes = [];
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = false;
  bool _usersLoading = false;
  bool _subjectsLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllQuizzes();
    _loadAllUsers(); // Load users immediately
    _tabController.addListener(() {
      if (_tabController.index == 1 && _allUsers.isEmpty && !_usersLoading) {
        _loadAllUsers();
      } else if (_tabController.index == 2 && _subjects.isEmpty && !_subjectsLoading) {
        _loadSubjects();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllQuizzes() async {
    setState(() => _isLoading = true);
    try {
      print('🔍 Loading all quizzes...');
      final quizzes = await _apiService.getAllQuizzes();
      print('📊 Received ${quizzes.length} quizzes: ${quizzes.map((q) => q.title).toList()}');
      setState(() => _allQuizzes = quizzes);
    } catch (e) {
      print('❌ Error loading quizzes: $e');
      Get.snackbar('Error', 'Failed to load quizzes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAllUsers() async {
    setState(() => _usersLoading = true);
    try {
      print('🔍 Loading all users...');
      final users = await _apiService.getAllUsers();
      print('📊 Received ${users.length} users: $users');
      setState(() => _allUsers = users);
    } catch (e) {
      print('❌ Error loading users: $e');
      Get.snackbar('Error', 'Failed to load users: $e');
    } finally {
      setState(() => _usersLoading = false);
    }
  }

  Future<void> _loadSubjects() async {
    setState(() => _subjectsLoading = true);
    try {
      final subjects = await _apiService.getSubjects();
      setState(() => _subjects = subjects);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load subjects: $e');
    } finally {
      setState(() => _subjectsLoading = false);
    }
  }

  Future<void> _changeUserRole(String userId, String newRole) async {
    try {
      final result = await _apiService.updateUserRole(
        userId: userId,
        role: newRole,
      );
      
      if (result['success']) {
        await _loadAllUsers();
        Get.snackbar('Success', 'User role updated successfully');
      } else {
        Get.snackbar('Error', result['message'] ?? 'Failed to update user role');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update user role: $e');
    }
  }

  Future<void> _approveUser(String userId, bool isApproved) async {
    try {
      final result = await _apiService.updateUserApproval(
        userId: userId,
        isApproved: isApproved,
      );
      
      if (result['success']) {
        await _loadAllUsers(); // Refresh user data
        setState(() {}); // Trigger UI rebuild for analytics
        Get.snackbar('Success', 'User approval status updated', backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('Error', result['message'] ?? 'Failed to update approval status', backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update approval status: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _deleteUser(String userId, String userEmail) async {
    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete user "$userEmail"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      try {
        final result = await _apiService.deleteUser(userId: userId);
        
        if (result['success']) {
          await _loadAllUsers(); // Refresh user data
          setState(() {}); // Trigger UI rebuild for analytics
          Get.snackbar('Success', 'User deleted successfully', backgroundColor: Colors.green, colorText: Colors.white);
        } else {
          Get.snackbar('Error', result['message'] ?? 'Failed to delete user', backgroundColor: Colors.red, colorText: Colors.white);
        }
      } catch (e) {
        Get.snackbar('Error', 'Failed to delete user: $e', backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  Future<void> _suspendUser(String userId, bool isSuspended) async {
    try {
      final result = await _apiService.suspendUser(
        userId: userId,
        isSuspended: isSuspended,
      );
      
      if (result['success']) {
        await _loadAllUsers(); // Refresh user data
        setState(() {}); // Trigger UI rebuild for analytics
        final action = isSuspended ? 'suspended' : 'activated';
        Get.snackbar('Success', 'User $action successfully', backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('Error', result['message'] ?? 'Failed to update user status', backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update user status: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    Get.dialog(
      Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          width: MediaQuery.of(Get.context!).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('User Details', style: AppTextStyle.h2)),
                  IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow('Name', '${user['firstName']} ${user['lastName']}'),
              _buildDetailRow('Email', user['email']),
              _buildDetailRow('Role', user['role'].toString().toUpperCase()),
              _buildDetailRow('Status', user['isApproved'] == true ? 'Approved' : 'Pending Approval'),
              _buildDetailRow('Account', user['isActive'] == true ? 'Active' : 'Suspended'),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Approve button for any pending user
                  if (user['isApproved'] != true)
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        _approveUser(user['id'], true);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  
                  // Suspend/Activate button
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      _suspendUser(user['id'], user['isActive'] == true);
                    },
                    icon: Icon(user['isActive'] == true ? Icons.block : Icons.check_circle),
                    label: Text(user['isActive'] == true ? 'Suspend' : 'Activate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: user['isActive'] == true ? Colors.orange : Colors.blue,
                    ),
                  ),
                  
                  // Delete button
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      _deleteUser(user['id'], user['email']);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text('$label:', style: AppTextStyle.bodyMedium.copyWith(fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: AppTextStyle.bodyMedium)),
        ],
      ),
    );
  }

  void _openCreateSubjectDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Create New Subject'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Subject Name'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final result = await _apiService.createSubject(
                  name: nameController.text,
                  description: descController.text,
                );
                if (result['success']) {
                  Get.back();
                  _loadSubjects();
                  Get.snackbar('Success', 'Subject created');
                } else {
                  Get.snackbar('Error', result['message'] ?? 'Failed to create');
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openEditSubjectDialog(Map<String, dynamic> subject) {
    final nameController = TextEditingController(text: subject['name']);
    final descController = TextEditingController(text: subject['description'] ?? '');

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Subject'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Subject Name'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final result = await _apiService.updateSubject(
                  subjectId: subject['id'],
                  name: nameController.text,
                  description: descController.text,
                );
                if (result['success']) {
                  Get.back();
                  _loadSubjects();
                  Get.snackbar(
                    'Success', 
                    'Subject updated successfully',
                    backgroundColor: AppColors.successColor,
                    colorText: AppColors.secondaryColor,
                  );
                } else {
                  Get.snackbar(
                    'Error', 
                    result['message'] ?? 'Failed to update subject',
                    backgroundColor: AppColors.errorColor,
                    colorText: AppColors.secondaryColor,
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSubject(String subjectId, String subjectName) async {
    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "$subjectName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      try {
        final result = await _apiService.deleteSubject(subjectId: subjectId);
        
        if (result['success']) {
          _loadSubjects(); // Refresh subjects list
          Get.snackbar(
            'Success', 
            'Subject deleted successfully',
            backgroundColor: AppColors.successColor,
            colorText: AppColors.secondaryColor,
          );
        } else {
          Get.snackbar(
            'Error', 
            result['message'] ?? 'Failed to delete subject',
            backgroundColor: AppColors.errorColor,
            colorText: AppColors.secondaryColor,
          );
        }
      } catch (e) {
        Get.snackbar(
          'Error', 
          'Failed to delete subject: $e',
          backgroundColor: AppColors.errorColor,
          colorText: AppColors.secondaryColor,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.secondaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Get.to(() => const ProfileScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _apiService.logout();
              Get.offAllNamed('/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Quizzes'),
            Tab(text: 'Users'),
            Tab(text: 'Subjects'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllQuizzesTab(),
          _buildUsersTab(),
          _buildSubjectsTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildAllQuizzesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allQuizzes.isEmpty) {
      return const Center(child: Text('No quizzes found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allQuizzes.length,
      itemBuilder: (context, index) {
        final quiz = _allQuizzes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(quiz.title),
            subtitle: Text('Created by: ${quiz.createdByFirstName} ${quiz.createdByLastName}'),
            trailing: Chip(
              label: Text(quiz.isPublished ? 'Published' : 'Draft'),
              backgroundColor: quiz.isPublished ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUsersTab() {
    if (_usersLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text('No users found', style: AppTextStyle.h3.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _loadAllUsers, child: const Text('Retry')),
          ],
        ),
      );
    }

    // Separate users by status
    final pendingTeachers = _allUsers.where((u) => u['role'] == 'teacher' && u['isApproved'] != true).toList();
    final pendingApprovals = _allUsers.where((u) => u['isApproved'] != true).toList(); // All pending users
    final suspendedUsers = _allUsers.where((u) => u['isActive'] != true).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards - Mobile friendly layout
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard('Total Users', '${_allUsers.length}', Icons.people, Colors.blue)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Pending Approval', '${pendingApprovals.length}', Icons.pending, Colors.orange)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Suspended', '${suspendedUsers.length}', Icons.block, Colors.red)),
                  const SizedBox(width: 8),
                  Expanded(child: Container()), // Empty space for balance
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Pending Approvals Section (All users needing approval)
          if (pendingApprovals.isNotEmpty) ...[
            Text('Pending Approvals (${pendingApprovals.length})', style: AppTextStyle.h2.copyWith(color: Colors.orange)),
            const SizedBox(height: 12),
            ...pendingApprovals.map((user) => _buildUserCard(user, isPending: true)),
            const SizedBox(height: 24),
          ],

          // All Users Section
          Text('All Users', style: AppTextStyle.h2),
          const SizedBox(height: 12),
          ..._allUsers.map((user) => _buildUserCard(user)),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, {bool isPending = false}) {
    final isActive = user['isActive'] == true;
    final isApproved = user['isApproved'] == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isPending ? 3 : 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: isPending ? Border.all(color: Colors.orange, width: 2) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${user['firstName']} ${user['lastName']}', 
                             style: AppTextStyle.h3.copyWith(color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text(user['email'], 
                             style: AppTextStyle.bodyMedium.copyWith(color: Colors.black54)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user['role']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(user['role'].toUpperCase(), 
                                   style: TextStyle(color: _getRoleColor(user['role']), 
                                                  fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 4),
                      if (!isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('SUSPENDED', 
                                           style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      if (!isApproved)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('PENDING', 
                                           style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Mobile-friendly action buttons - Single column layout
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // View Details Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showUserDetails(user),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Action buttons row
                  Row(
                    children: [
                      // Approval Button (for any unapproved user)
                      if (!isApproved)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _approveUser(user['id'], true),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      
                      if (!isApproved) const SizedBox(width: 8),
                      
                      // Suspend/Activate Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _suspendUser(user['id'], isActive),
                          icon: Icon(isActive ? Icons.block : Icons.check_circle, size: 16),
                          label: Text(isActive ? 'Suspend' : 'Activate'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isActive ? Colors.orange : Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Delete Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _deleteUser(user['id'], user['email']),
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin': return Colors.red;
      case 'teacher': return Colors.blue;
      default: return Colors.green;
    }
  }

  Widget _buildSubjectsTab() {
    if (_subjectsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: _subjects.isEmpty
          ? const Center(child: Text('No subjects found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final subject = _subjects[index];
                return Card(
                  child: ListTile(
                    title: Text(subject['name']),
                    subtitle: Text(subject['description'] ?? ''),
                    leading: const Icon(Icons.book),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _openEditSubjectDialog(subject),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteSubject(subject['id'], subject['name']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateSubjectDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    // Ensure we have loaded user data
    if (_allUsers.isEmpty && !_usersLoading) {
      _loadAllUsers();
    }
    
    final studentCount = _allUsers.where((u) => (u['role'] as String).toLowerCase() == 'student').length;
    final teacherCount = _allUsers.where((u) => (u['role'] as String).toLowerCase() == 'teacher').length;
    final adminCount = _allUsers.where((u) => (u['role'] as String).toLowerCase() == 'admin').length;
    final pendingApprovals = _allUsers.where((u) => u['isApproved'] != true).length; // All pending users
    final suspendedUsers = _allUsers.where((u) => u['isActive'] != true).length;
    final publishedQuizzes = _allQuizzes.where((q) => q.isPublished).length;
    final draftQuizzes = _allQuizzes.where((q) => !q.isPublished).length;

    print('📊 Analytics Data: Students=$studentCount, Teachers=$teacherCount, Admins=$adminCount, Total=${_allUsers.length}');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Overview', style: AppTextStyle.h2),
          const SizedBox(height: 16),
          
          // Main Statistics - Mobile friendly
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard('Total Users', '${_allUsers.length}', Icons.people, Colors.blue)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Total Quizzes', '${_allQuizzes.length}', Icons.quiz, Colors.green)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Published Quizzes', '$publishedQuizzes', Icons.publish, Colors.teal)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Draft Quizzes', '$draftQuizzes', Icons.drafts, Colors.orange)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text('User Analytics', style: AppTextStyle.h2),
          const SizedBox(height: 16),
          
          // User Role Distribution - Mobile friendly
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard('Students', '$studentCount', Icons.school, Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Teachers', '$teacherCount', Icons.person, Colors.blue)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Admins', '$adminCount', Icons.admin_panel_settings, Colors.red)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Pending Approvals', '$pendingApprovals', Icons.pending, Colors.orange)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Suspended Users', '$suspendedUsers', Icons.block, Colors.red)),
                  const SizedBox(width: 8),
                  Expanded(child: Container()), // Empty space
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // User Distribution Chart
          if (_allUsers.isNotEmpty) ...[
            Text('User Role Distribution', style: AppTextStyle.h3),
            const SizedBox(height: 16),
            _buildUserDistributionChart(),
          ] else if (_usersLoading) ...[
            const Center(child: CircularProgressIndicator()),
          ] else ...[
            Center(
              child: Column(
                children: [
                  const Text('No user data available'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadAllUsers,
                    child: const Text('Load Users'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(value, 
                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(title, 
                   style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500), 
                   textAlign: TextAlign.center, 
                   maxLines: 2, 
                   overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserDistributionChart() {
    if (_allUsers.isEmpty) return const SizedBox.shrink();
    
    int studentCount = _allUsers.where((u) => (u['role'] as String).toLowerCase() == 'student').length;
    int teacherCount = _allUsers.where((u) => (u['role'] as String).toLowerCase() == 'teacher').length;
    int adminCount = _allUsers.where((u) => (u['role'] as String).toLowerCase() == 'admin').length;
    int total = _allUsers.length;

    print('📊 User Distribution: Students=$studentCount, Teachers=$teacherCount, Admins=$adminCount, Total=$total');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildChartBar('Students', studentCount, total, Colors.green),
          const SizedBox(height: 8),
          _buildChartBar('Teachers', teacherCount, total, Colors.blue),
          const SizedBox(height: 8),
          _buildChartBar('Admins', adminCount, total, Colors.red),
        ],
      ),
    );
  }

  Widget _buildChartBar(String label, int count, int total, Color color) {
    double percentage = total > 0 ? count / total : 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('$label: $count', 
                           style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
                           overflow: TextOverflow.ellipsis),
              ),
              Text('${(percentage * 100).toInt()}%', 
                   style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage, 
              color: color, 
              backgroundColor: color.withOpacity(0.2),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}