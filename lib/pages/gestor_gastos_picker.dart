// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class DateTimePicker extends StatefulWidget {
  const DateTimePicker({Key? key}) : super(key: key);

  @override
  _DateTimePickerState createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<DateTimePicker> {
  DateTime? _selectedDate;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  void _showDatePicker(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, DateTime>>(
      context: context,
      builder: (BuildContext context) => DateSelectionScreen(
        rangeStart: _rangeStart,
        rangeEnd: _rangeEnd,
      ),
    );

    if (result != null) {
      setState(() {
        _rangeStart = result['start'];
        _rangeEnd = result['end'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => _showDatePicker(context),
            child: const Text("Filtro por fecha"),
          ),
          const SizedBox(height: 16),
          Text(
            'Rango seleccionado: ${_rangeStart?.toString() ?? 'No seleccionado'} - ${_rangeEnd?.toString() ?? 'No seleccionado'}',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class DateSelectionScreen extends StatefulWidget {
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  const DateSelectionScreen({Key? key, this.rangeStart, this.rangeEnd})
      : super(key: key);

  @override
  _DateSelectionScreenState createState() => _DateSelectionScreenState();
}

class _DateSelectionScreenState extends State<DateSelectionScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _rangeStart = widget.rangeStart ?? _focusedDay;
    _rangeEnd = widget.rangeEnd ?? _focusedDay;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = focusedDay;
      _focusedDay = focusedDay;
      _rangeStart = start ?? focusedDay;
      _rangeEnd = end ?? focusedDay;
    });
  }

  void _applyFilter() {
    Navigator.of(context).pop({'start': _rangeStart, 'end': _rangeEnd});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 900,
      child: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: _onDaySelected,
            rangeStartDay: _rangeStart,
            rangeSelectionMode: RangeSelectionMode.toggledOn,
            onRangeSelected: _onRangeSelected,
            rangeEndDay: _rangeEnd,
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
          ),
          ElevatedButton(
            onPressed: _applyFilter,
            child: const Text("Aplicar filtro"),
          ),
        ],
      ),
    );
  }
}
