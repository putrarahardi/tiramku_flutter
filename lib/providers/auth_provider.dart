import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;

  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiService.post('login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        _user = response.data['user'];
        _isAuthenticated = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        
        notifyListeners();
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }
  Future<bool> register(String name, String email, String password, {String? phone, String? address}) async {
    try {
      final response = await _apiService.post('register', {
        'name': name,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['access_token'];
        _user = response.data['user'];
        _isAuthenticated = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        
        notifyListeners();
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<bool> updateProfile(String name, String phone, String address, {String? photoPath}) async {
    try {
      Response response;
      if (photoPath != null) {
        final formData = FormData.fromMap({
          'name': name,
          'phone': phone,
          'address': address,
          '_method': 'PUT',
          'photo': await MultipartFile.fromFile(
            photoPath,
            filename: photoPath.split('/').last,
          ),
        });
        response = await _apiService.post('user', formData);
      } else {
        response = await _apiService.put('user', {
          'name': name,
          'phone': phone,
          'address': address,
        });
      }

      if (response.statusCode == 200) {
        _user = response.data['user'];
        notifyListeners();
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<void> logout() async {
    await _apiService.post('logout', {});
    _isAuthenticated = false;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    notifyListeners();
  }
}
