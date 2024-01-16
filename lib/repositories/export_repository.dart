import 'package:cashbook/models/export.dart';
import 'package:dio/dio.dart';

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

  Future<List<Export>> fetchExports() async {
    final response = await dio.get('/api/export');
    final List<dynamic> data = response.data;
    return data.map((json) => Export.fromJson(json)).toList();
  }
}
