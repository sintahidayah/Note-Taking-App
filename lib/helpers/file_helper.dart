import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/note.dart';

class FileHelper {
  // Pola Singleton [cite: 1524, 1621]
  static final FileHelper instance = FileHelper._internal();
  FileHelper._internal();
  factory FileHelper() => instance;

  // Akses direktori dokumen aplikasi [cite: 1140, 1527]
  Future<Directory> _getNotesDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final notesDir = Directory(join(docsDir.path, 'notes'));
    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }
    return notesDir;
  }

  // Simpan catatan (Soal 4: Menyertakan baris waktu modifikasi) [cite: 1541, 2038]
  Future<void> saveNote(String noteId, String title, String content) async {
    final notesDir = await _getNotesDirectory();
    final noteDir = Directory(join(notesDir.path, noteId));
    if (!await noteDir.exists()) await noteDir.create(recursive: true);

    final file = File(join(noteDir.path, 'content.txt'));
    final timestamp = DateTime.now()
        .toIso8601String(); // Metadata ISO 8601 [cite: 2038]

    // Baris 1: Judul, Baris 2: Waktu, Baris 3+: Isi [cite: 2039]
    await file.writeAsString('$title\n$timestamp\n$content');
  }

  // Baca catatan (Soal 5: Deteksi jumlah gambar) [cite: 1552, 2041, 2047]
  Future<Note?> readNote(String noteId) async {
    final notesDir = await _getNotesDirectory();
    final file = File(join(notesDir.path, noteId, 'content.txt'));
    if (!await file.exists()) return null;

    final rawContent = await file.readAsString();
    final lines = rawContent.split('\n');

    // Hitung keberadaan file image_1 sampai image_3 [cite: 2046, 2048]
    int count = 0;
    for (int i = 1; i <= 3; i++) {
      if (await File(join(notesDir.path, noteId, 'image_$i.jpg')).exists()) {
        count++;
      }
    }

    return Note(
      id: noteId,
      title: lines.isNotEmpty ? lines[0] : '',
      lastModified: lines.length > 1 ? lines[1] : '',
      content: lines.length > 2 ? lines.sublist(2).join('\n') : '',
      imageCount: count,
    );
  }

  // Simpan gambar dengan kompresi (Soal 5: Indeks 1-3) [cite: 1431, 1591, 2048]
  Future<void> saveNoteImage(
    String noteId,
    int index,
    String sourcePath,
  ) async {
    final notesDir = await _getNotesDirectory();
    final noteDir = Directory(join(notesDir.path, noteId));
    if (!await noteDir.exists()) await noteDir.create(recursive: true);

    final originalBytes = await File(sourcePath).readAsBytes();
    final compressedBytes = await FlutterImageCompress.compressWithList(
      originalBytes,
      quality: 70, // Kualitas 70 untuk efisiensi [cite: 1449, 2016]
      minWidth: 1080,
      minHeight: 1080,
      format: CompressFormat.jpeg,
    );

    final imageFile = File(join(noteDir.path, 'image_$index.jpg'));
    await imageFile.writeAsBytes(compressedBytes!);
  }

  // Hapus satu gambar spesifik [cite: 1313, 2048]
  Future<void> deleteNoteImage(String noteId, int index) async {
    final notesDir = await _getNotesDirectory();
    final imageFile = File(join(notesDir.path, noteId, 'image_$index.jpg'));
    if (await imageFile.exists()) await imageFile.delete();
  }

  // Ekspor ke direktori sementara (Soal 3) [cite: 1140, 2032]
  Future<String> exportNote(String noteId) async {
    final note = await readNote(noteId);
    if (note == null) throw Exception("Note not found");

    final tempDir = await getTemporaryDirectory();
    final exportFile = File(join(tempDir.path, 'export_$noteId.txt'));

    await exportFile.writeAsString(
      "TITLE: ${note.title}\nMODIFIED: ${note.lastModified}\n---\n${note.content}",
    );
    return exportFile.path;
  }

  // Ambil semua catatan [cite: 1336, 1576]
  Future<List<Note>> getAllNotes() async {
    final notesDir = await _getNotesDirectory();
    final List<Note> notes = [];
    if (await notesDir.exists()) {
      await for (final entity in notesDir.list()) {
        if (entity is Directory) {
          final id = entity.path.split(Platform.pathSeparator).last;
          final note = await readNote(id);
          if (note != null) notes.add(note);
        }
      }
    }
    notes.sort(
      (a, b) => b.id.compareTo(a.id),
    ); // Urutkan terbaru [cite: 1346, 1584]
    return notes;
  }

  // Hapus folder catatan utuh [cite: 1314, 1614]
  Future<void> deleteNote(String noteId) async {
    final notesDir = await _getNotesDirectory();
    final noteDir = Directory(join(notesDir.path, noteId));
    if (await noteDir.exists()) await noteDir.delete(recursive: true);
  }

  Future<File?> getNoteImageFile(String noteId, int index) async {
    final notesDir = await _getNotesDirectory();
    final imageFile = File(join(notesDir.path, noteId, 'image_$index.jpg'));
    return await imageFile.exists() ? imageFile : null;
  }
}
