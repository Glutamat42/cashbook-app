import 'package:dio/dio.dart';
import '../models/entry.dart';

class ExportRepository {
  final Dio dio;

  ExportRepository(this.dio);

  Future<void> createExport(bool exportDocuments, bool convertToJpeg) async {
    await dio.post('/api/export/create',
        data: FormData.fromMap({
          "convert_to_jpeg": convertToJpeg ? 1 : 0,
          "export_documents": exportDocuments ? 1 : 0,
        }));
  }
}
