import 'package:flutter/widgets.dart';
import 'package:flutter_file_loader/files.dart';

class InheritedFileUploader extends InheritedWidget {
  final FileUploadManager manager;

  InheritedFileUploader({ this.manager, Widget child }): super(child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;

  static InheritedFileUploader of(BuildContext context) =>
    context.inheritFromWidgetOfExactType(InheritedFileUploader);
}