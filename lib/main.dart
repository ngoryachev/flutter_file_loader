import 'package:flutter/material.dart';

import 'file_uploader_screen.dart';

void main() => runApp(MyApp());

// TODO Мега костыль, от которого очевидно следует избавиться в первую очередь
// Переменная для обмена данными между экранами
List<String> superMegaGlobalFileList = [];

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

  bool _hasFiles = false;

  void _navToFileUploadScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext screenContext) => FileUploaderScreen(),
      ),
    );
    _updateState();
  }

  void _clearFiles() {
    superMegaGlobalFileList = [];
    _updateState();
  }

  void _updateState() {
    setState(() {
      _hasFiles = superMegaGlobalFileList.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            onPressed: _hasFiles ? _clearFiles : null,
          ),
          FlatButton(
            child: Text('Сохранить'),
            onPressed: _hasFiles ? () {} : null,
          )
        ],
      )
    );
  }

  Text _buildFileSubtitle() {
    if (!_hasFiles) {
      return Text("Нет файлов");
    }
    // TODO Раскоментировать и реализовать очередь
    // if (fileUploader.isUploading) {
    //   final queueLen = fileUploader.queue.length;
    //   final total = fileUploader.files.length + queueLen;
    //   return Text("Осталось загрузить: $queueLen. Всего файлов: $total");
    // }
    return Text("Кол-во файлов: ${superMegaGlobalFileList.length} ");
  }
}