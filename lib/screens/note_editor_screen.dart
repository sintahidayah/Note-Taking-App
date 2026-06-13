import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Impor ini sekarang akan berfungsi
import '../models/note.dart';
import '../helpers/file_helper.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final FileHelper _fileHelper = FileHelper.instance;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  // Menggunakan 'final' untuk memperbaiki peringatan prefer_final_fields
  final List<File?> _images = [null, null, null];
  bool _isSaving = false;
  late String _resolvedNoteId;

  @override
  void initState() {
    super.initState();
    // Inisialisasi ID catatan
    _resolvedNoteId =
        widget.note?.id ?? 'note_${DateTime.now().millisecondsSinceEpoch}';

    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _loadImages();
    }
  }

  Future<void> _loadImages() async {
    for (int i = 0; i < 3; i++) {
      final file = await _fileHelper.getNoteImageFile(_resolvedNoteId, i + 1);
      if (mounted && file != null) {
        setState(() => _images[i] = file);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker(); // Memperbaiki undefined_method
    // Memperbaiki undefined_identifier ImageSource
    final XFile? xFile = await picker.pickImage(source: ImageSource.gallery);

    if (xFile != null) {
      int emptyIndex = _images.indexWhere((img) => img == null);
      if (emptyIndex != -1) {
        setState(() => _images[emptyIndex] = File(xFile.path));
      }
    }
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Simpan teks utama
      await _fileHelper.saveNote(
        _resolvedNoteId,
        _titleController.text,
        _contentController.text,
      );

      // Kelola sinkronisasi 3 gambar (Soal 5)
      for (int i = 0; i < 3; i++) {
        if (_images[i] != null) {
          // Hanya kompres dan simpan jika file berasal dari luar direktori catatan
          if (!_images[i]!.path.contains(_resolvedNoteId)) {
            await _fileHelper.saveNoteImage(
              _resolvedNoteId,
              i + 1,
              _images[i]!.path,
            );
          }
        } else {
          // Jika slot kosong, hapus file fisiknya di penyimpanan
          await _fileHelper.deleteNoteImage(_resolvedNoteId, i + 1);
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int currentCount = _images.where((img) => img != null).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Catatan Baru' : 'Edit Catatan'),
        actions: [
          _isSaving
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : IconButton(icon: const Icon(Icons.save), onPressed: _saveNote),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Judul',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            TextField(
              controller: _contentController,
              maxLines: null,
              minLines: 5,
              decoration: const InputDecoration(
                hintText: 'Tulis catatanmu...',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 20),

            // Tampilan daftar gambar horizontal (Soal 5)
            if (currentCount > 0)
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (ctx, i) {
                    if (_images[i] == null) return const SizedBox();
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 120,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _images[i]!,
                              fit: BoxFit.cover,
                            ), // Image.file lebih efisien
                          ),
                        ),
                        Positioned(
                          right: 15,
                          top: 5,
                          child: GestureDetector(
                            onTap: () => setState(() => _images[i] = null),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: currentCount < 3 ? _pickImage : null,
              icon: const Icon(Icons.add_a_photo),
              label: Text('Lampirkan Gambar ($currentCount/3)'),
            ),
          ],
        ),
      ),
    );
  }
}
