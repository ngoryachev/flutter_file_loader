import 'package:flutter/material.dart';
import 'package:flutter_file_loader/file_uploader_inherited_widget.dart';
import 'package:flutter_file_loader/file_uploader.dart';

class FileUploaderScreen extends StatefulWidget {
  @override
  _FileUploaderScreenState createState() => _FileUploaderScreenState();
}

class _FileUploaderScreenState extends State<FileUploaderScreen> {

  List<FileUploadStatus> statuses;

  FileUploader manager;
  VoidCallback unsubscribe;

  dispose() {
    super.dispose();
    unsubscribe();
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
    if (manager == null) {
      manager = InheritedFileUploader.of(context).fileUploader;
      statuses = manager.fileUploadStatuses.toList();
      unsubscribe = manager.addItemsChangeListener(handleItemsChanged);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Файлы"),
      ),
      body: Container(
        child: _buildFileList(),
      ),
      floatingActionButton: Visibility(visible: !manager.isFileCountLimit(), child: FloatingActionButton(
        onPressed: _addFile,
        tooltip: 'Add file',
        child: Icon(Icons.add),
      ),
    ));
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
        final subtitle = {
          UploadState.uploaded: '',
          UploadState.uploading: 'Загружается',
          UploadState.waiting: 'В ожидании'
        }[statuses[i].state];

        return ListTile(
          title: Text(statuses[i].name),
          trailing: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              _removeFileByIndex(i);
            },
          ),
          subtitle: Text(subtitle),
        );
      }
    );
  }

}