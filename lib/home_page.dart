import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> _data = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    ReceivePort receivePort = ReceivePort();
    Isolate isolate = await Isolate.spawn(_fetchDataInIsolate, receivePort.sendPort);

    receivePort.listen((message) {
      if (message is List<String>) {
        setState(() {
          _data = List.from(message);
        });
        receivePort.close();
        isolate.kill();
      }
    });
  }

  static void _fetchDataInIsolate(SendPort sendPort) async {
    try {
      final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/photos'));
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        final List<String> images = responseData.map((e) => e['url'] as String).toList();
        sendPort.send(images);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      sendPort.send(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('API Call with Isolate.spawn Example'),
        centerTitle: true,
      ),
      body: Center(
        child: (_data.isEmpty)
            ? const CircularProgressIndicator()
            : RefreshIndicator(
                onRefresh: fetchData,
                child: ListView.builder(
                  itemCount: _data.length,
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      child: Image.network(_data[index]),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
