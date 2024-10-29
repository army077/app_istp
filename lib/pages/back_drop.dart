import 'package:flutter/material.dart';

class BackdropPage extends StatefulWidget {
  const BackdropPage({Key? key}) : super(key: key);

  @override
  State<BackdropPage> createState() => _BackdropPageState();
}

class _BackdropPageState extends State<BackdropPage> {
  List<bool> _isExpandedList = List.generate(50, (index) => false);

  void _toggleExpansion(int index) {
    setState(() {
      _isExpandedList[index] = !_isExpandedList[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Backdrop Demo'),
      ),
      body: ListView.builder(
        itemCount: 50,
        itemBuilder: (BuildContext context, int index) {
          return Column(
            children: <Widget>[
              ExpansionTile(
                title: Text('Item $index'),
                trailing: Icon(_isExpandedList[index]
                    ? Icons.expand_less
                    : Icons.expand_more),
                onExpansionChanged: (isExpanded) => _toggleExpansion(index),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'More information for item $index, bla, bla, bla, bla',
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
