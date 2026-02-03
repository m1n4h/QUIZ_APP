// File: lib/screens/teacher/edit_quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiz_app/models/quiz_model.dart';
import 'package:quiz_app/services/api_service.dart';

class EditQuizScreen extends StatefulWidget {
  final Quiz quiz;
  final VoidCallback onSaved;

  const EditQuizScreen({
    super.key,
    required this.quiz,
    required this.onSaved,
    // required this.allowReview,
    // required this .showScore,
  });

  @override
  State<EditQuizScreen> createState() => _EditQuizScreenState();
}

class _EditQuizScreenState extends State<EditQuizScreen> {
  final ApiService _apiService = Get.find<ApiService>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _timeLimitController;
  bool _isLoading = false;
  DateTime? _scheduledStart;
  DateTime? _scheduledEnd;
  bool _allowReview = true;
  bool _showScore = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quiz.title);
    _descriptionController = TextEditingController(text: widget.quiz.description);
    _timeLimitController = TextEditingController(text: '${widget.quiz.timeLimit}');
    _scheduledStart = widget.quiz.scheduledStart;
    _scheduledEnd = widget.quiz.scheduledEnd;
    _allowReview = widget.quiz.allowReview;
    _showScore = widget.quiz.showScore;
  }

  Future<void> _saveQuiz() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.updateQuiz(
        quizId: widget.quiz.id,
        title: _titleController.text,
        description: _descriptionController.text,
        timeLimit: int.parse(_timeLimitController.text),
        scheduledStart: _scheduledStart,
        scheduledEnd: _scheduledEnd,
        allowReview: _allowReview,
        showScore: _showScore,
      );

      Get.back();
      widget.onSaved();
      Get.snackbar(
        'Success',
        'Quiz updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update quiz: $e',
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
      initialDate: isStart ? (_scheduledStart ?? DateTime.now()) : (_scheduledEnd ?? DateTime.now()),
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

  void _clearSchedule(bool isStart) {
    setState(() {
      if (isStart) {
        _scheduledStart = null;
      } else {
        _scheduledEnd = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Quiz'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveQuiz,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Quiz Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintMaxLines: 3,
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
            Card(
              child: ListTile(
                title: Text(
                  _scheduledStart == null 
                      ? 'Schedule Start (Optional)'
                      : 'Start: ${_scheduledStart!.toString()}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_scheduledStart != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => _clearSchedule(true),
                      ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
                onTap: () => _selectDate(context, true),
              ),
            ),
            
            // Schedule End
            Card(
              child: ListTile(
                title: Text(
                  _scheduledEnd == null 
                      ? 'Schedule End (Optional)'
                      : 'End: ${_scheduledEnd!.toString()}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_scheduledEnd != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => _clearSchedule(false),
                      ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
                onTap: () => _selectDate(context, false),
              ),
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
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
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