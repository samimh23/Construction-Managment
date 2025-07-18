import 'package:dio/dio.dart';
import '../Core/Constants/api_constants.dart';
import '../Model/Constructionsite/ConstructionSiteModel.dart';

class SiteService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    headers: ApiConstants.defaultHeaders,
    connectTimeout: Duration(milliseconds: ApiConstants.connectTimeout),
    receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
    sendTimeout: Duration(milliseconds: ApiConstants.sendTimeout),
  ));

  Future<ConstructionSite> addSite(ConstructionSite site) async {
    final response = await _dio.post(
      ApiConstants.CreateConstructionsite,
      data: site.toJson(),
    );
    if (response.statusCode == ApiConstants.statusOk ||
        response.statusCode == ApiConstants.statusCreated) {
      return ConstructionSite.fromJson(response.data);
    } else {
      throw Exception('Failed to add site: ${response.data}');
    }
  }

  Future<List<ConstructionSite>> fetchSites() async {
    final response = await _dio.get(ApiConstants.GetConstructionsites);
    if (response.statusCode == ApiConstants.statusOk) {
      final List data = response.data;
      return data.map((e) => ConstructionSite.fromJson(e)).toList();
    }
    throw Exception('Failed to load sites: ${response.data}');
  }

  Future<ConstructionSite> fetchSiteById(String id) async {
    final response = await _dio.get('${ApiConstants.GetConstructionsiteById}$id');
    if (response.statusCode == ApiConstants.statusOk) {
      return ConstructionSite.fromJson(response.data);
    }
    throw Exception('Failed to load site: ${response.data}');
  }

  Future<ConstructionSite> updateSite(ConstructionSite site) async {
    final response = await _dio.patch(
      '${ApiConstants.UpdateConstructionsite}${site.id}',
      data: site.toJson(),
    );
    if (response.statusCode == ApiConstants.statusOk) {
      return ConstructionSite.fromJson(response.data);
    }
    throw Exception('Failed to update site: ${response.data}');
  }

  Future<void> deleteSite(String id) async {
    final response = await _dio.delete('${ApiConstants.DeleteConstructionsite}$id');
    if (response.statusCode != ApiConstants.statusOk &&
        response.statusCode != ApiConstants.statusNoContent) {
      throw Exception('Failed to delete site: ${response.data}');
    }
  }
}