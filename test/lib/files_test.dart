import 'package:flutter_file_loader/file_uploader.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart';

void main() {
  testApi(FileUploader manager, {
    bool canSave,
    bool canReset,
    int fileCount,
    bool isFileCountLimit,
    Function fileUploadStatusesMatcher,
  }) {
    if (canSave != null ) expect(manager.canSave(), canSave);
    if (canReset != null ) expect(manager.canReset(), canReset);
    if (fileCount != null ) expect(manager.fileCount, fileCount);
    if (isFileCountLimit != null ) expect(manager.isFileCountLimit(), isFileCountLimit);
    if (fileUploadStatusesMatcher != null)
      expect(fileUploadStatusesMatcher(manager.fileUploadStatuses), isTrue);
  }

  test('creation ok', () async {
    final manager = FileUploader();
    testApi(manager,
      canSave: false,
      canReset: false,
      fileCount: 0,
      isFileCountLimit: false,
      fileUploadStatusesMatcher: (statuses) => statuses.length == 0,
    );
  });

  test('add one file', () async {
    final manager = FileUploader();
    final id = manager.appendFile();
    testApi(manager,
      canSave: false,
      canReset: true,
      fileCount: 1,
      isFileCountLimit: false,
      fileUploadStatusesMatcher: (Iterable<FileUploadStatus> statuses) {
        return statuses.length == 1 && statuses.first.state == UploadState.uploading;
      },
    );

    await manager.getUploadFuture(id);

    testApi(manager,
      canSave: true,
      canReset: true,
      fileCount: 1,
      isFileCountLimit: false,
      fileUploadStatusesMatcher: (Iterable<FileUploadStatus> statuses) {
        FileUploadStatus first = statuses.first;

        return first.name == 'Файл #1' &&
          statuses.length == 1 && first.state == UploadState.uploaded;
      },
    );
  });

  test('add one file and cancel', () async {
    final manager = FileUploader();
    manager.appendFile();

    await Future.delayed(Duration(milliseconds: 500));

    manager.reset();

    testApi(manager, fileCount: 0);

    await Future.delayed(Duration(seconds: FileUploader.UPLOAD_DURATION_MAX));

    testApi(manager, fileCount: 0);
  });

  test('simultaneous loading files test', () async {
    final manager = FileUploader();
    manager.appendFile();
    manager.appendFile();
    manager.appendFile();
    manager.appendFile();

    testApi(manager, fileCount: 4, fileUploadStatusesMatcher: (Iterable<FileUploadStatus> statuses) {
      final list = statuses.toList();
      return list[0].state == UploadState.uploading &&
        list[1].state == UploadState.uploading &&
        list[2].state == UploadState.uploading &&
        list[3].state == UploadState.waiting;
    });
  });

  test('delete file test', () async {
    final manager = FileUploader();
    manager.appendFile();
    final list = manager.fileUploadStatuses.toList();
    expect(list[0].state, UploadState.uploading);
    expect(list.length, 1);
    manager.delete(list[0].id);
    final newList = manager.fileUploadStatuses.toList();
    expect(newList.length, 0);
  });

  test('after waiting file become uploading', () async {
    final manager = FileUploader();
    final id1 = manager.appendFile();
    final id2 = manager.appendFile();
    final id3 = manager.appendFile();

    final id4 = manager.appendFile();

    expect(manager.fileUploadStatuses.toList()[3].state, UploadState.waiting);

    await Future.any([id1, id2, id3].map((id) => manager.getUploadFuture(id)));

    expect(manager.fileUploadStatuses.toList()[3].state, UploadState.uploading);

    await Future.wait([id1, id2, id3, id4].map((id) => manager.getUploadFuture(id)));

    expect(manager.fileUploadStatuses.every((status) => status.state == UploadState.uploaded),
      true
    );
  });
}