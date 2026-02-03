// File: lib/screens/teacher/create_quiz_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_app/services/api_service.dart';

class CreateQuizDialog extends StatefulWidget {
  final VoidCallback onQuizCreated;

  const CreateQuizDialog({super.key, required this.onQuizCreated});

  @override
  State<CreateQuizDialog> createState() => _CreateQuizDialogState();
}

class _CreateQuizDialogState extends State<CreateQuizDialog> {
  final ApiService _apiService = Get.find<ApiService>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeLimitController = TextEditingController(text: '30');
  bool _isLoading = false;
  DateTime? _scheduledStart;
  DateTime? _scheduledEnd;
  bool _allowReview = true;
  bool _showScore = true;

  Future<void> _createQuiz() async {
    if (_titleController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter quiz title',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
// Check authentication first
    final token = _apiService.getToken();
    if (token == null || token.isEmpty) {
      Get.snackbar(
        'Authentication Required',
        'Please login again',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      // Optionally redirect to login
      Get.offAllNamed('/login');
      return;
    }

    print('Creating quiz with token: ${token.substring(0, 20)}...');

    setState(() => _isLoading = true);
    try {
      await _apiService.createQuiz(
        title: _titleController.text,
        description: _descriptionController.text,
        timeLimit: int.parse(_timeLimitController.text),
        scheduledStart: _scheduledStart,
        scheduledEnd: _scheduledEnd,
        allowReview: _allowReview,
        showScore: _showScore,
      );

      Get.back();
      widget.onQuizCreated();
      Get.snackbar(
        'Success',
        'Quiz created successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create quiz: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      if (time != null) {
        setState(() {
          final dateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
          if (isStart) {
            _scheduledStart = dateTime;
          } else {
            _scheduledEnd = dateTime;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Quiz'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Quiz Title *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _timeLimitController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Time Limit (minutes)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Schedule Start
            ListTile(
              title: Text(
                _scheduledStart == null 
                    ? 'Schedule Start (Optional)'
                    : 'Start: ${_scheduledStart!.toString()}',
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, true),
            ),
            
            // Schedule End
            ListTile(
              title: Text(
                _scheduledEnd == null 
                    ? 'Schedule End (Optional)'
                    : 'End: ${_scheduledEnd!.toString()}',
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, false),
            ),
            
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _allowReview,
                  onChanged: (value) {
                    setState(() {
                      _allowReview = value ?? true;
                    });
                  },
                ),
                const Text('Allow Review'),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: _showScore,
                  onChanged: (value) {
                    setState(() {
                      _showScore = value ?? true;
                    });
                  },
                ),
                const Text('Show Score Immediately'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createQuiz,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Create Quiz'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }
}