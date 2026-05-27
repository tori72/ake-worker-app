// lib/features/sales/providers/sales_form_provider.dart
// State management for the Sales Transaction form using ChangeNotifier

import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';
import '../models/dropdown_options_model.dart';

enum FormLoadState { idle, loading, loaded, error }

enum SubmitState { idle, submitting, success, error }

class SalesFormProvider extends ChangeNotifier {
  // ─── Dropdown data ──────────────────────────
  DropdownOptionsModel _options = DropdownOptionsModel.empty();
  FormLoadState _loadState = FormLoadState.idle;
  String _loadError = '';

  // ─── Form selections ─────────────────────────
  LookupOption? _selectedItem;
  LookupOption? _selectedThread;
  LookupOption? _selectedLength;
  LookupOption? _selectedHead;
  LookupOption? _selectedColour;
  String? _selectedUom;
  String? _selectedMode;

  // ─── Computed amount ─────────────────────────
  double _quantity = 0;
  double _rate = 0;

  // ─── Submit state ────────────────────────────
  SubmitState _submitState = SubmitState.idle;
  String _submitError = '';

  // ─────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────

  DropdownOptionsModel get options => _options;
  FormLoadState get loadState => _loadState;
  String get loadError => _loadError;
  SubmitState get submitState => _submitState;
  String get submitError => _submitError;

  LookupOption? get selectedItem => _selectedItem;
  LookupOption? get selectedThread => _selectedThread;
  LookupOption? get selectedLength => _selectedLength;
  LookupOption? get selectedHead => _selectedHead;
  LookupOption? get selectedColour => _selectedColour;
  String? get selectedUom => _selectedUom;
  String? get selectedMode => _selectedMode;

  double get amount => _quantity * _rate;

  // ─────────────────────────────────────────────
  // Setters
  // ─────────────────────────────────────────────

  void setItem(LookupOption? v) {
    _selectedItem = v;
    notifyListeners();
  }

  void setThread(LookupOption? v) {
    _selectedThread = v;
    notifyListeners();
  }

  void setLength(LookupOption? v) {
    _selectedLength = v;
    notifyListeners();
  }

  void setHead(LookupOption? v) {
    _selectedHead = v;
    notifyListeners();
  }

  void setColour(LookupOption? v) {
    _selectedColour = v;
    notifyListeners();
  }

  void setUom(String? v) {
    _selectedUom = v;
    notifyListeners();
  }

  void setMode(String? v) {
    _selectedMode = v;
    notifyListeners();
  }

  void setQuantity(String v) {
    _quantity = double.tryParse(v) ?? 0;
    notifyListeners();
  }

  void setRate(String v) {
    _rate = double.tryParse(v) ?? 0;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Load dropdown options from API
  // ─────────────────────────────────────────────

  Future<void> loadOptions() async {
    if (_loadState == FormLoadState.loading) return;

    _loadState = FormLoadState.loading;
    _loadError = '';

    try {
      _options = await ApiService.instance.fetchDropdownOptions();
      _loadState = FormLoadState.loaded;
    } on ApiException catch (e) {
      _loadState = FormLoadState.error;
      _loadError = e.message;
    } catch (e) {
      _loadState = FormLoadState.error;
      _loadError = 'Unexpected error: $e';
    } finally {
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // Submit transaction
  // ─────────────────────────────────────────────

  Future<bool> submit({
    required String date,
    required String party,
    required String quantity,
    required String rate,
  }) async {
    _submitState = SubmitState.submitting;
    _submitError = '';
    notifyListeners();

    try {
      await ApiService.instance.createTransaction({
        'date': date,
        'party': party,
        'item_id': _selectedItem!.id,
        'thread_id': _selectedThread!.id,
        'length_id': _selectedLength!.id,
        'head_id': _selectedHead!.id,
        'colour_id': _selectedColour!.id,
        'quantity': int.parse(quantity),
        'uom': _selectedUom,
        'rate': double.parse(rate),
        'mode': _selectedMode,
      });

      _submitState = SubmitState.success;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _submitState = SubmitState.error;
      _submitError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _submitState = SubmitState.error;
      _submitError = 'Unexpected error: $e';
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Reset form
  // ─────────────────────────────────────────────

  void resetForm() {
    _selectedItem = null;
    _selectedThread = null;
    _selectedLength = null;
    _selectedHead = null;
    _selectedColour = null;
    _selectedUom = null;
    _selectedMode = null;
    _quantity = 0;
    _rate = 0;
    _submitState = SubmitState.idle;
    _submitError = '';
    notifyListeners();
  }
}
