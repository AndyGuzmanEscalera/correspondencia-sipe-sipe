import 'dart:typed_data';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/attachments_section.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class Picker extends FilePicker {
  bool? multiple;
  @override
  Future<FilePickerResult?> pickFiles({String? dialogTitle, String? initialDirectory,
    FileType type = FileType.any, List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading, bool allowCompression = true,
    int compressionQuality = 30, bool allowMultiple = false, bool withData = false,
    bool withReadStream = false, bool lockParentWindow = false,
    bool readSequential = false}) async {
    multiple = allowMultiple;
    return FilePickerResult([
      PlatformFile(name: 'a.pdf', size: 4, bytes: Uint8List.fromList('%PDF'.codeUnits)),
      PlatformFile(name: 'b.pdf', size: 4, bytes: Uint8List.fromList('%PDF'.codeUnits)),
    ]);
  }
}
void main() {
  testWidgets('multiple selection shows names and sizes and permits removal', (tester) async {
    final picker = Picker();
    FilePicker.platform = picker;
    final inherited = UpsertCorrespondenceInherited(typeOperation: TypeOperation.create,
      child: const AttachmentsSection());
    addTearDown(inherited.dispose);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: inherited)));
    expect(find.text('Adjuntos'), findsOneWidget);
    await tester.tap(find.text('Agregar archivos'));
    await tester.pumpAndSettle();
    expect(picker.multiple, isTrue);
    expect(find.text('a.pdf'), findsOneWidget);
    expect(find.text('b.pdf'), findsOneWidget);
    expect(inherited.pendingAttachments.first.mimeType, 'application/pdf');
    await tester.tap(find.byTooltip('Quitar').first);
    await tester.pumpAndSettle();
    expect(find.text('a.pdf'), findsNothing);
    expect(inherited.pendingAttachments.single.filename, 'b.pdf');
  });
}
