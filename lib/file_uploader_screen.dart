import 'package:flutter/material.dart';
import 'package:flutter_file_loader/files.dart';

import 'main.dart';

class FileUploaderScreen extends StatefulWidget {
  @override
  _FileUploaderScreenState createState() => _FileUploaderScreenState();
}

class _FileUploaderScreenState extends State<FileUploaderScreen> {

  List<FileUploadStatus> statuses;

  initState() {
    super.initState();
    statuses = manager.fileUploadStatuses.toList();
    manager.addItemsChangeListener(handleItemsChanged);
  }

  dispose() {
    super.dispose();
    manager.removeItemsChangeListener(handleItemsChanged);
  }

  void handleItemsChanged(Iterable<FileUploadStatus> statuses) {
    setState(() {
      this.statuses = manager.fileUploadStatuses.toList();
    });
  }

  void _addFile() {
    manager.appendFile();
  }

  void _removeFileByIndex(int index) {
    manager.delete(manager.getId(index));
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
    if (statuses.isEmpty) {
      return Center(
        child: Text('Нет файлов')
      );
    }

    return ListView.builder(
      itemCount: statuses.length,
      itemBuilder: (context, i) {
        return ListTile(
          title: Text(statuses[i].name),
          trailing: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              _removeFileByIndex(i);
            },
          ),
          subtitle: statuses[i].state != UploadState.uploaded ? Text('Загружается') : null,
        );
      }
    );
  }

}