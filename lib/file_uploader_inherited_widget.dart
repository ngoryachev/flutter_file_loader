import 'package:flutter/widgets.dart';
import 'package:flutter_file_loader/file_uploader.dart';

class InheritedFileUploader extends InheritedWidget {
  final FileUploader fileUploader;

  InheritedFileUploader({ this.fileUploader, Widget child }): super(child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;

  static InheritedFileUploader of(BuildContext context) =>
    context.inheritFromWidgetOfExactType(InheritedFileUploader);
}