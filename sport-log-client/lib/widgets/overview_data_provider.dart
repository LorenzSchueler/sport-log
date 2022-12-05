import 'package:flutter/material.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/widgets/snackbar.dart';

class OverviewDataProvider<T, R, D extends DataProvider<T>, S>
    extends ChangeNotifier {
  OverviewDataProvider({
    required D dataProvider,
    required this.entityAccessor,
    required this.recordAccessor,
    required String loggerName,
  })  : _dataProvider = dataProvider,
        _logger = Logger(loggerName);

  final Logger _logger;
  final D _dataProvider;
  Future<bool> pullFromServer() => _dataProvider.pullFromServer();
  final Future<List<T>> Function(DateTime?, DateTime?, S?, String?) Function(D)
      entityAccessor;
  final Future<R> Function() Function(D) recordAccessor;

  DateFilterState _dateFilter = MonthFilter.current();
  DateFilterState get dateFilter => _dateFilter;
  set dateFilter(DateFilterState dateFilter) {
    _dateFilter = dateFilter;
    notifyListeners();
    _update();
  }

  S? _selected;
  S? get selected => _selected;
  set selected(S? selected) {
    _selected = selected;
    notifyListeners();
    _update();
  }

  bool get isSelected => _selected != null;

  String? _search;
  String? get search => _search;
  set search(String? search) {
    _search = search;
    notifyListeners();
    _update();
  }

  bool get isSearch => _search != null;

  List<T> _entities = [];
  List<T> get entities => _entities;
  R? _records;
  R? get records => _records;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void init() {
    _dataProvider
      ..addListener(_update)
      ..onNoInternetConnection = () => showNoInternetToast(App.globalContext);
    _update();
  }

  @override
  void dispose() {
    _dataProvider
      ..removeListener(_update)
      ..onNoInternetConnection = null;
    super.dispose();
  }

  Future<void> _update() async {
    _isLoading = true;
    notifyListeners();
    _logger.d(
      'Updating with start = ${_dateFilter.start}, end = ${_dateFilter.end}, selected = $_selected, search = $_search',
    );
    _entities = await entityAccessor(_dataProvider)(
      _dateFilter.start,
      _dateFilter.end,
      selected,
      search,
    );
    _records = await recordAccessor(_dataProvider)();
    _isLoading = false;
    notifyListeners();
    _logger.d("Update finished.");
  }
}
