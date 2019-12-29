import 'package:flutter/material.dart';

import 'main.dart';

class FileUploaderScreen extends StatefulWidget {
  @override
  _FileUploaderScreenState createState() => _FileUploaderScreenState();
}

class _FileUploaderScreenState extends State<FileUploaderScreen> {

  List<String> _files = superMegaGlobalFileList;

  void _addFile() {
    setState(() {
      _files.add("Файл ${_files.length}");
    });
  }

  void _removeFileByIndex(int index) {
    setState(() {
      _files.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Файлы"),
      ),
      body: Container(
        child: _buildFileList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFile,
        tooltip: 'Add file',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildFileList() {
    if (_files.isEmpty) {
      return Center(
        child: Text('Нет файлов')
      );
    }

    return ListView.builder(
      itemCount: _files.length,
      itemBuilder: (context, i) {
        return ListTile(
          title: Text(_files[i]),
          trailing: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              _removeFileByIndex(i);
            },
          ),
          subtitle: false ? Text('Загружается') : null,
        );
      }
    );
  }

}