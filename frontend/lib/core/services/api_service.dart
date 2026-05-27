// lib/core/services/api_service.dart
// HTTP service — all REST calls go through here.
// Flutter ↔ Node.js backend ONLY. No direct Supabase calls.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../../features/sales/models/dropdown_options_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final http.Client _client = http.Client();

  // ─────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$path');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(AppConstants.connectTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection or server unreachable.');
    } on TimeoutException {
      throw ApiException('Request timed out. Check your network connection.');
    }
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$path');
      final response = await _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(AppConstants.connectTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection or server unreachable.');
    } on TimeoutException {
      throw ApiException('Request timed out. Check your network connection.');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = decoded['error'] as String? ?? 'Unknown server error';
    throw ApiException(message, statusCode: response.statusCode);
  }

  // ─────────────────────────────────────────────
  // Public API methods
  // ─────────────────────────────────────────────

  /// Fetches all dropdown option lists in a single request.
  Future<DropdownOptionsModel> fetchDropdownOptions() async {
    if (AppConstants.useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 150));
      return const DropdownOptionsModel(
        items: [
          LookupOption(id: 1, label: 'Screw M4'),
          LookupOption(id: 2, label: 'Screw M6'),
          LookupOption(id: 3, label: 'Bolt M8'),
          LookupOption(id: 4, label: 'Nut M4'),
          LookupOption(id: 5, label: 'Washer'),
        ],
        threads: [
          LookupOption(id: 1, label: 'Metric'),
          LookupOption(id: 2, label: 'Imperial'),
          LookupOption(id: 3, label: 'UNC'),
          LookupOption(id: 4, label: 'UNF'),
          LookupOption(id: 5, label: 'BSW'),
        ],
        lengths: [
          LookupOption(id: 1, label: '10mm'),
          LookupOption(id: 2, label: '20mm'),
          LookupOption(id: 3, label: '30mm'),
          LookupOption(id: 4, label: '50mm'),
          LookupOption(id: 5, label: '100mm'),
        ],
        heads: [
          LookupOption(id: 1, label: 'Phillips'),
          LookupOption(id: 2, label: 'Flat'),
          LookupOption(id: 3, label: 'Hex'),
          LookupOption(id: 4, label: 'Counter-sink'),
        ],
        colours: [
          LookupOption(id: 1, label: 'Zinc'),
          LookupOption(id: 2, label: 'Black Oxide'),
          LookupOption(id: 3, label: 'Steel'),
          LookupOption(id: 4, label: 'Brass'),
        ],
      );
    }

    final response = await _get('/items/all');
    return DropdownOptionsModel.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  /// Posts a new sales transaction to the backend.
  Future<Map<String, dynamic>> createTransaction(
      Map<String, dynamic> payload) async {
    if (AppConstants.useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      return {
        'id': 123,
        'status': 'success',
        'message': 'Mock transaction created successfully'
      };
    }

    final response = await _post('/transactions', payload);
    return response['data'] as Map<String, dynamic>;
  }
}
