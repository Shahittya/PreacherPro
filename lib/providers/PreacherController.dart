import 'package:flutter/material.dart';
import '../models/PreacherData.dart';

class PreacherController extends ChangeNotifier {
  // We can expose the stream directly for the UI to listen to via StreamBuilder
  Stream<List<PreacherData>> get preachersStream => PreacherData.getPreachersStream();

  // Wrapper methods for CRUD operations
  
  Future<void> addPreacher(PreacherData preacher) async {
    await PreacherData.addPreacher(preacher);
    notifyListeners(); // Optional if stream updates UI automatically
  }

  Future<void> updatePreacher(PreacherData preacher) async {
    await PreacherData.updatePreacher(preacher);
    notifyListeners();
  }

  Future<void> updatePreacherStatus(String id, String status) async {
    await PreacherData.updatePreacherStatus(id, status);
    notifyListeners();
  }

  Future<void> deletePreacher(String id) async {
    await PreacherData.deletePreacher(id);
    notifyListeners();
  }

  Future<PreacherData?> getPreacherById(String id) {
    return PreacherData.getPreacherById(id);
  }
}
