import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseHealthChecker {
  static Future<Map<String, bool>> checkFirebaseHealth() async {
    final results = <String, bool>{};
    
    try {
      // Check if Firebase is initialized
      results['firebase_initialized'] = Firebase.apps.isNotEmpty;
      debugPrint('🔥 Firebase initialized: ${results['firebase_initialized']}');
      
      if (!results['firebase_initialized']!) {
        return results;
      }
      
      // Check Firestore connection
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('health_check').limit(1).get();
        results['firestore_connection'] = true;
        debugPrint('✅ Firestore connection: OK');
      } catch (e) {
        results['firestore_connection'] = false;
        debugPrint('❌ Firestore connection error: $e');
      }
      
      // Check Firestore write permission
      try {
        final firestore = FirebaseFirestore.instance;
        final testDoc = firestore.collection('health_check').doc('test');
        await testDoc.set({
          'timestamp': FieldValue.serverTimestamp(),
          'test': true,
        });
        await testDoc.delete();
        results['firestore_write'] = true;
        debugPrint('✅ Firestore write permission: OK');
      } catch (e) {
        results['firestore_write'] = false;
        debugPrint('❌ Firestore write permission error: $e');
      }
      
    } catch (e) {
      debugPrint('❌ Firebase health check error: $e');
    }
    
    return results;
  }
  
  static Future<void> testCallLogWrite() async {
    try {
      debugPrint('🧪 Testing call log write...');
      
      final firestore = FirebaseFirestore.instance;
      final testData = {
        'customerId': 'test-customer-id',
        'phoneNumber': '+84123456789',
        'callTime': Timestamp.now(),
        'status': 'test',
        'platform': defaultTargetPlatform.toString(),
        'timestamp': FieldValue.serverTimestamp(),
        'isTest': true,
      };
      
      final docRef = await firestore.collection('call_logs').add(testData);
      debugPrint('✅ Test call log created with ID: ${docRef.id}');
      
      // Clean up
      await docRef.delete();
      debugPrint('🗑️ Test call log deleted');
      
    } catch (e) {
      debugPrint('❌ Test call log write error: $e');
    }
  }
  
  static Future<void> testCustomerUpdate() async {
    try {
      debugPrint('🧪 Testing customer update...');
      
      final firestore = FirebaseFirestore.instance;
      final testData = {
        'name': 'Test Customer',
        'phone': '+84123456789',
        'address': 'Test Address',
        'reminders': [],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'isTest': true,
      };
      
      final docRef = await firestore.collection('customers').add(testData);
      debugPrint('✅ Test customer created with ID: ${docRef.id}');
      
      // Test update
      await docRef.update({
        'reminders': [
          {
            'reminderDate': Timestamp.now(),
            'description': 'Test reminder',
            'isCompleted': false,
            'createdAt': Timestamp.now(),
          }
        ],
        'updatedAt': Timestamp.now(),
      });
      debugPrint('✅ Test customer updated successfully');
      
      // Clean up
      await docRef.delete();
      debugPrint('🗑️ Test customer deleted');
      
    } catch (e) {
      debugPrint('❌ Test customer update error: $e');
    }
  }
}
