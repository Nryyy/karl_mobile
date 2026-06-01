import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

/// Diagnostic widget to test Firestore connection and configuration
class FirestoreDiagnosticWidget extends StatefulWidget {
  const FirestoreDiagnosticWidget({super.key});

  @override
  State<FirestoreDiagnosticWidget> createState() => _FirestoreDiagnosticWidgetState();
}

class _FirestoreDiagnosticWidgetState extends State<FirestoreDiagnosticWidget> {
  bool _isTesting = false;
  String _testResult = '';
  Color _resultColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Firestore діагностика',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              'Перевірте підключення до Firestore та налаштування бази даних.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _testFirestoreConnection,
                icon: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(_isTesting ? 'Тестування...' : 'Тестувати Firestore'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            if (_testResult.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _resultColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _resultColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _resultColor == Colors.green ? Icons.check_circle : 
                          _resultColor == Colors.red ? Icons.error : 
                          Icons.info,
                          color: _resultColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Результат тесту:',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _resultColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _testResult,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            _buildTroubleshootingGuide(colorScheme),
          ],
        ),
      ),
    );
  }

  Future<void> _testFirestoreConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = '';
      _resultColor = Colors.grey;
    });

    try {
      // Test 1: Basic Firestore connection
      developer.log('Testing Firestore connection...', name: 'karl.diagnostic');
      
      // Test 2: Try to read a simple document
      final testDoc = await FirebaseFirestore.instance
          .collection('_diagnostics')
          .doc('connection_test')
          .get();
      
      developer.log('Firestore read test completed', name: 'karl.diagnostic');
      
      // Test 3: Try to write a simple document
      await FirebaseFirestore.instance
          .collection('_diagnostics')
          .doc('connection_test')
          .set({
            'test': true,
            'timestamp': DateTime.now().toIso8601String(),
            'platform': 'flutter',
          });
      
      developer.log('Firestore write test completed', name: 'karl.diagnostic');
      
      // Test 4: Try to read it back
      final verifyDoc = await FirebaseFirestore.instance
          .collection('_diagnostics')
          .doc('connection_test')
          .get();
      
      if (verifyDoc.exists && verifyDoc.data()?['test'] == true) {
        setState(() {
          _testResult = '✅ Firestore працює коректно!\n\n'
              '• Підключення: Успішно\n'
              '• Читання: Успішно\n'
              '• Запис: Успішно\n'
              '• Верифікація: Успішно\n\n'
              'База даних готова до використання.';
          _resultColor = Colors.green;
        });
      } else {
        throw Exception('Data verification failed');
      }
      
    } catch (e) {
      developer.log('Firestore test failed: $e', name: 'karl.diagnostic', error: e);
      
      String errorMessage = e.toString();
      String troubleshooting = '';
      
      if (errorMessage.contains('permission-denied')) {
        troubleshooting = '\n\n💡 Рішення: Перевірте Security Rules в Firebase Console';
      } else if (errorMessage.contains('unavailable') || errorMessage.contains('connection')) {
        troubleshooting = '\n\n💡 Рішення: Перевірте, чи Firestore створено в Firebase Console';
      } else if (errorMessage.contains('not-found')) {
        troubleshooting = '\n\n💡 Рішення: Створіть Firestore базу даних в Firebase Console';
      } else {
        troubleshooting = '\n\n💡 Рішення: Перевірте налаштування Firebase проєкту';
      }
      
      setState(() {
        _testResult = '❌ Помилка Firestore: ${e.toString()}$troubleshooting';
        _resultColor = Colors.red;
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Widget _buildTroubleshootingGuide(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔧 Інструкція налаштування:',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildStep('1. Firebase Console → ваш проєкт'),
          _buildStep('2. Firestore Database → Create database'),
          _buildStep('3. Start in test mode'),
          _buildStep('4. Виберіть регіон (напр. europe-west1)'),
          _buildStep('5. Security Rules → додайте правила'),
          _buildStep('6. Publish rules'),
          _buildStep('7. Перезапустіть додаток'),
        ],
      ),
    );
  }

  Widget _buildStep(String step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(
            child: Text(
              step,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
