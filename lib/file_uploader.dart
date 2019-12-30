//Требования по главному экрану:
//  [✅, X] Кнопка [Сбросить] заблокирована, если файлов нет;
//  [✅, X] Кнопка [Сохранить] заблокирована, если:
//    Файлов нет;
//    Процесс загрузки хотя бы одного файла не завершен.

// ===

//  [✅, X] При клике на [Сбросить] список файлов очищается, в том числе загружаемые в этот момент файлы.
//  [✅, X] При клике на [Сохранить] появляется нотификация с текстом “Файлы сохранены”.
//  [✅, ✅] При клике на элемент с текстом “Файлы” переходим на экран загрузки файлов.
//  У кликабельного элемента должен быть один из подзаголовков с текстом:
//    Нет файлов.
//    “Кол-во файлов: N” - если все файлы успешно загружены, где N - это кол-во файлов.
//    “Осталось загрузить: M. Всего файлов: N” - где M - это кол-во файлов, которые не в статусе Успешно загружен, а N - все файлы в любом статусе.
//
//Требования по экрану загрузки файлов:
//  Если список файлов пуст, то на экране выводится текст “Нет файлов”.
//  [✅, X] При клике на кнопку [Добавить файл] добавляется один элемент “Файл #N” в конец списка файлов.
//  [✅, X] Если “Файл” попал в очередь на загрузку (Загружается), под этим файлом пишем текст “Загружается”;
//  [✅, X] Если очередь по загрузке переполнена, под файлами, которые еще не загружены пишем текст “В ожидании”;
//  [✅, X] Если “Файл” в статусе Успешно загружен, ничего под ним писать не надо;
//  [✅, X] Любой файл в любом статусе можно удалить (см. скриншот).
//  [✅, X] Кнопка [Добавить файл] видна только тогда, когда кол-во файлов < 30.
//  [✅, X] Имя файла можно генерировать на свое усмотрение.

import 'dart:async';
import 'dart:math';

import 'package:async/async.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

enum UploadState {
  waiting,
  uploading,
  uploaded,
}

void noop() => {};

typedef void ChangeListener(Iterable<FileUploadStatus> statuses);

class FileUploader {
  static const int _MAX_SIMULTANEOUS_UPLOADING_FILES = 3;
  static const int _MAX_FILES_TOTAL = 30;

  static const int UPLOAD_DURATION_MIN = 1;
  static const int UPLOAD_DURATION_MAX = 5;

  BuiltList<FileUploadStatus> _uploadStatuses;
  BuiltMap<String, CancelableOperation> _uploadOperations;

  BuiltList<ChangeListener> _changeListeners;

  final Random _random;
  final Uuid _uuid;

  FileUploader(): _random = Random(), _uuid = Uuid() {
    // TODO load state from persistence

    _uploadStatuses = BuiltList();
    _changeListeners = BuiltList();
    _uploadOperations = BuiltMap();
  }

  VoidCallback addItemsChangeListener(ChangeListener listener) {
    _changeListeners = _changeListeners.rebuild((list) => list.add(listener));

    return () { removeItemsChangeListener(listener); };
  }

  void removeItemsChangeListener(ChangeListener listener) {
    _changeListeners = _changeListeners.rebuild((list) => list.remove(listener));
  }

  String upload(String name) {
    if (_uploadStatuses.length == _MAX_FILES_TOTAL) {
      throw 'max_limit_error';
    }

    final needWait = _getCountByState(UploadState.uploading) == _MAX_SIMULTANEOUS_UPLOADING_FILES;
    UploadState uploadState = needWait ? UploadState.waiting : UploadState.uploading;

    final id = _uuid.v1();

    _uploadStatuses = _uploadStatuses.rebuild((statuses) {
      statuses.add(FileUploadStatus(id, uploadState, name));
    });

    if (!needWait) {
      _startUploading(id);
    }

    return id;
  }

  void _startUploading(String id) {
    CancelableOperation co = CancelableOperation.fromFuture(
      Future.delayed(Duration(seconds: UPLOAD_DURATION_MIN + _random.nextInt(UPLOAD_DURATION_MAX))),
      onCancel: () => _handleOperationCancelled(id),
    );

    _uploadOperations = _uploadOperations.rebuild((operations) => operations[id] = co);

    _notify();

    co.value.then((_) => _handleOperationDone(id));
  }

  int _getCountByState(UploadState state) =>
    _uploadStatuses.where((FileUploadStatus file) => file.state == state).toList().length;

  bool canReset() {
    return _uploadStatuses.length > 0;
  }

  bool canSave() {
    return _uploadStatuses.length > 0 && _getCountByState(UploadState.uploaded) == _uploadStatuses.length;
  }

  int get fileCount => _uploadStatuses.length;

  bool isFileCountLimit() => _uploadStatuses.length == _MAX_FILES_TOTAL;

  Future<void> save() async {
    if(!canSave()) {
      throw 'save_error';
    }

    // TODO persist state

    return true;
  }

  bool reset() {
    if (!canReset()) {
      return false;
    }

    _uploadOperations.forEach((id, co) => co.cancel());
    _uploadOperations = BuiltMap();
    _uploadStatuses = BuiltList();

    _notify();

    return true;
  }

  String appendFile() {
    int count = fileCount;

    return upload('Файл #${count + 1}');
  }

  String getId(int index) => _uploadStatuses.toList()[index].id;

  void delete(String id) {
    _uploadOperations = _uploadOperations.rebuild((map) {
      CancelableOperation co = map.remove(id);

      if (co != null) {
        co.cancel();
      }

      _uploadStatuses = _uploadStatuses.rebuild((statuses) {
        statuses.removeWhere((status) => status.id == id);
      });

      _notify();
    });

    _handleUploadStatusesCountDecreased();
  }

  Iterable<FileUploadStatus> get fileUploadStatuses => _uploadStatuses.toBuiltList();

  _handleOperationDone(String id) {
    int index = _uploadStatuses.indexWhere((FileUploadStatus s) => s.id == id);
    FileUploadStatus targetElement = _uploadStatuses[index];

    _uploadStatuses = _uploadStatuses.rebuild((statuses) {
      statuses[index] = targetElement.setState(UploadState.uploaded);
    });

    _uploadOperations = _uploadOperations.rebuild((ops) => ops.remove(id));

    _notify();

    _handleUploadStatusesCountDecreased();

    return targetElement;
  }

  _handleOperationCancelled(String id) {
    _uploadStatuses = _uploadStatuses.rebuild((ss) => ss.removeWhere((s) => s.id == id));

    _uploadOperations = _uploadOperations.rebuild((ops) => ops.remove(id));

    _notify();

    _handleUploadStatusesCountDecreased();
  }

  // done/delete/cancelled
  _handleUploadStatusesCountDecreased() {
    int uploading = _getCountByState(UploadState.uploading);
    int waiting = _getCountByState(UploadState.waiting);
    int vacant = _MAX_SIMULTANEOUS_UPLOADING_FILES - uploading;

    if (vacant > 0 && waiting > 0) {
      _uploadStatuses = _uploadStatuses.rebuild((statuses) {
        statuses.map((status) {
          if (status.state == UploadState.waiting && vacant > 0 && waiting > 0) {
            final newStatus = status.setState(UploadState.uploading);

            _startUploading(status.id);

            vacant--;
            waiting--;

            return newStatus;
          }

          return status;
        });
      });
    }
  }

  Future getUploadFuture(String id) {
    if (_uploadOperations[id] != null) {
      return _uploadOperations[id].value;
    }

    return Future.value();
  }

  _notify() {
    _changeListeners.forEach((Function cb) => cb(fileUploadStatuses));
  }
}

@immutable
class FileUploadStatus {
  final String id;
  final UploadState state;
  final String name;

  FileUploadStatus(this.id, this.state, this.name);

  FileUploadStatus setState(UploadState state) => FileUploadStatus(id, state, name);
}