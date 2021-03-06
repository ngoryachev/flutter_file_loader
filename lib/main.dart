import 'package:flutter/material.dart';
import 'package:flutter_file_loader/file_uploader_inherited_widget.dart';
import 'package:flutter_file_loader/file_uploader.dart';

import 'file_uploader_screen.dart';

void main() => runApp(InheritedFileUploader(child: MyApp(), fileUploader: FileUploader()));

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Тестовое задание',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<FileUploadStatus> statuses;

  FileUploader manager;
  VoidCallback unsubscribe;

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  dispose() {
    super.dispose();
    unsubscribe();
  }

  void handleItemsChanged(Iterable<FileUploadStatus> statuses) {
    setState(() {
      this.statuses = manager.fileUploadStatuses.toList();
    });
  }

  void _handleClickSave() {
    manager.save().then((_) {
      _scaffoldKey.currentState.showSnackBar(new SnackBar(content: new Text('Файлы сохранены')));
    });
  }

  void _navToFileUploadScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext screenContext) => FileUploaderScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (manager == null) {
      manager = InheritedFileUploader.of(context).fileUploader;
      statuses = manager.fileUploadStatuses.toList();
      unsubscribe = manager.addItemsChangeListener(handleItemsChanged);
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Home page'),
      ),
      body: Container(
        child: ListTile(
          title: Text("Файлы"),
          trailing: Icon(Icons.arrow_forward_ios),
          subtitle: _buildFileSubtitle(),
          onTap: _navToFileUploadScreen,
        ),
      ),
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          FlatButton(
            child: Text('Сбросить'),
            onPressed: manager.canReset() ? (){ manager.reset(); } : null,
          ),
          FlatButton(
            child: Text('Сохранить'),
            onPressed: manager.canSave() ? _handleClickSave : null,
          )
        ],
      )
    );
  }

  Text _buildFileSubtitle() {
    if (statuses.length == 0) {
      return Text("Нет файлов");
    }

    final pending = statuses.where((status) => status.state != UploadState.uploaded).toList().length;
    if (pending > 0) {
     return Text("Осталось загрузить: $pending. Всего файлов: ${statuses.length}");
    }

    return Text("Кол-во файлов: ${statuses.length} ");
  }
}