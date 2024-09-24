import 'package:flutter/material.dart';
import 'history_model.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<DiscountHistory> _historyList = [];
  List<DiscountHistory> _filteredHistoryList = [];
  DiscountHistory? _lastDeletedHistory;
  int? _lastDeletedIndex;
  Timer? _timer;
  int _countdownDuration = 10; // Duration in seconds
  TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  String _sortBy = 'date_desc'; // Default sort by date descending

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _searchController.addListener(_filterHistory);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // Fetch history and apply filters/sorting
  void _fetchHistory() async {
    _historyList = await DatabaseHelper.instance.fetchHistory();
    _filterHistory(); // Apply search and sorting
  }

  // Filter history based on the search term
  void _filterHistory() {
    setState(() {
      _filteredHistoryList = _historyList.where((history) {
        return history.originalPrice
                .toLowerCase()
                .contains(_searchTerm.toLowerCase()) ||
            history.discount
                .toLowerCase()
                .contains(_searchTerm.toLowerCase()) ||
            history.finalPrice
                .toLowerCase()
                .contains(_searchTerm.toLowerCase());
      }).toList();

      // Sort the filtered list
      _sortHistory();
    });
  }

  // Sort history based on the selected sorting option
  void _sortHistory() {
    if (_sortBy == 'date_desc') {
      _filteredHistoryList.sort((a, b) => b.date.compareTo(a.date));
    } else if (_sortBy == 'date_asc') {
      _filteredHistoryList.sort((a, b) => a.date.compareTo(b.date));
    } else if (_sortBy == 'price_desc') {
      _filteredHistoryList.sort((a, b) =>
          double.parse(b.finalPrice).compareTo(double.parse(a.finalPrice)));
    } else if (_sortBy == 'price_asc') {
      _filteredHistoryList.sort((a, b) =>
          double.parse(a.finalPrice).compareTo(double.parse(b.finalPrice)));
    }
  }

  // Handling the removal of a history item
  void _removeHistory(int index) async {
    setState(() {
      _lastDeletedHistory = _filteredHistoryList[index];
      _lastDeletedIndex = index;
      _filteredHistoryList.removeAt(index);
      _historyList.remove(_lastDeletedHistory); // Also remove from main list
    });

    await DatabaseHelper.instance.deleteHistory(_lastDeletedHistory!.id!);
    _startCountdown();
    _showUndoSnackbar();
  }

  void _startCountdown() {
    _countdownDuration = 10; // Reset countdown
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdownDuration > 0) {
        setState(() {
          _countdownDuration--;
        });
      } else {
        _timer!.cancel();
        _lastDeletedHistory = null; // Clear the last deleted history
        _lastDeletedIndex = null; // Clear the last deleted index
      }
    });
  }

  void _showUndoSnackbar() {
    final snackBar = SnackBar(
      content: CountdownTimerIndicator(
        duration: _countdownDuration,
        onComplete: () {
          // Perform actions when the countdown completes, like deleting history permanently
          _lastDeletedHistory = null; // Clear the last deleted history
          _lastDeletedIndex = null; // Clear the last deleted index
        },
      ),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          _undoDelete();
        },
      ),
      duration: Duration(seconds: 10),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _undoDelete() {
    if (_lastDeletedHistory != null && _lastDeletedIndex != null) {
      setState(() {
        _historyList.insert(_lastDeletedIndex!, _lastDeletedHistory!);
        _lastDeletedHistory = null; // Clear the last deleted history
        _lastDeletedIndex = null; // Clear the last deleted index
        _timer?.cancel(); // Cancel the timer if the undo is pressed
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'History',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        iconTheme: IconThemeData(
          color: Colors.white, // Change the back button color to white
        ),
        actions: [
          IconButton(
            icon: Icon(
              _sortBy == 'date_desc'
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                // Toggle between newest and oldest sorting
                if (_sortBy == 'date_desc') {
                  _sortBy = 'date_asc';
                } else {
                  _sortBy = 'date_desc';
                }
                _filterHistory(); // Re-sort the list when the sort order changes
              });
            },
          ),
        ],
      ),
      body: _historyList.isEmpty
          ? Center(child: Text('No history available'))
          : ListView.builder(
              itemCount: _filteredHistoryList.length,
              itemBuilder: (context, index) {
                final history = _filteredHistoryList[index];
                return Dismissible(
                  key: Key(history.date), // Unique key for each item
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  onDismissed: (direction) {
                    _removeHistory(index); // Remove history on dismiss
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 5,
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Date:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd MMM yyyy, HH:mm')
                                        .format(DateTime.parse(history.date)),
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.blueAccent),
                                  ),
                                ],
                              ),
                              Divider(color: Colors.grey),
                              SizedBox(height: 5),
                              _buildDetailRow('Original Price',
                                  history.originalPrice, Colors.black87),
                              _buildDetailRow(
                                  'Discount', history.discount, Colors.green),
                              _buildDetailRow('Final Price', history.finalPrice,
                                  Colors.redAccent),
                              _buildDetailRow('Profit', history.profit,
                                  Colors.orangeAccent),
                              _buildDetailRow('Sell Price', history.sellprice,
                                  Colors.purpleAccent),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Helper method for cleaner code
Widget _buildDetailRow(String label, String value, Color valueColor) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: TextStyle(
              fontSize: 14, color: valueColor, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class CountdownTimerIndicator extends StatefulWidget {
  final int duration;
  final VoidCallback onComplete;

  CountdownTimerIndicator({required this.duration, required this.onComplete});

  @override
  _CountdownTimerIndicatorState createState() =>
      _CountdownTimerIndicatorState();
}

class _CountdownTimerIndicatorState extends State<CountdownTimerIndicator> {
  late int _countdown;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _countdown = widget.duration;
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer.cancel();
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: _countdown / widget.duration,
                backgroundColor: Colors.grey[300],
                strokeWidth: 4.0,
              ),
              Text(
                '$_countdown',
                style: TextStyle(
                  fontSize: 12, // Adjust the font size as needed
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'History deleted.\nUndo in $_countdown seconds.',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
