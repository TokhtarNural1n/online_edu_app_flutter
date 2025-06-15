// lib/screens/material_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/content_item_model.dart';

class MaterialDetailScreen extends StatelessWidget {
  final ContentItem materialItem;

  const MaterialDetailScreen({super.key, required this.materialItem});

  // Вспомогательный метод для выбора иконки по типу файла
  IconData _getIconForFileType(String? fileType) {
    switch (fileType?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'pptx':
      case 'ppt':
        return Icons.slideshow_rounded;
      case 'doc':
      case 'docx':
        return Icons.article_rounded;
      case 'png':
      case 'jpg':
      case 'jpeg':
        return Icons.image_rounded;
      default:
        return Icons.attach_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(materialItem.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Файлы для скачивания:',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Пока у нас только один файл, но мы уже строим интерфейс в виде списка
          if (materialItem.fileUrl != null && materialItem.fileName != null)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                leading: Icon(
                  _getIconForFileType(materialItem.fileType),
                  color: Theme.of(context).primaryColor,
                  size: 40,
                ),
                title: Text(
                  materialItem.fileName!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('Тип: ${materialItem.fileType?.toUpperCase() ?? "Неизвестно"}'),
                trailing: const Icon(Icons.download_for_offline_outlined),
                onTap: () async {
                  final uri = Uri.parse(materialItem.fileUrl!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Не удалось открыть файл: ${materialItem.fileName}')),
                      );
                    }
                  }
                },
              ),
            ),

          // Если файлов нет (на всякий случай)
          if (materialItem.fileUrl == null)
            const Center(child: Text("Для этого материала нет прикрепленных файлов.")),

        ],
      ),
    );
  }
}