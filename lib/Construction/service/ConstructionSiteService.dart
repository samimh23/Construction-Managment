import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Core/Constants/api_constants.dart';
import '../Model/Constructionsite/ConstructionSiteModel.dart';

class SiteService {
  // CREATE
  Future<ConstructionSite> addSite(ConstructionSite site) async {
    final response = await http.post(
      Uri.parse(ApiConstants.getFullUrl(ApiConstants.CreateConstructionsite)),
      headers: ApiConstants.defaultHeaders,
      body: json.encode(site.toJson()),
    );
    if (response.statusCode == ApiConstants.statusOk ||
        response.statusCode == ApiConstants.statusCreated) {
      return ConstructionSite.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add site: ${response.body}');
    }
  }

  // READ ALL
  Future<List<ConstructionSite>> fetchSites() async {
    final response = await http.get(
      Uri.parse(ApiConstants.getFullUrl(ApiConstants.GetConstructionsites)),
      headers: ApiConstants.defaultHeaders,
    );
    if (response.statusCode == ApiConstants.statusOk) {
      final List data = json.decode(response.body);
      return data.map((e) => ConstructionSite.fromJson(e)).toList();
    }
    throw Exception('Failed to load sites: ${response.body}');
  }

  // READ ONE
  Future<ConstructionSite> fetchSiteById(String id) async {
    final response = await http.get(
      Uri.parse(ApiConstants.getFullUrl('${ApiConstants.GetConstructionsiteById}$id')),
      headers: ApiConstants.defaultHeaders,
    );
    if (response.statusCode == ApiConstants.statusOk) {
      return ConstructionSite.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load site: ${response.body}');
  }

  // UPDATE
  Future<ConstructionSite> updateSite(ConstructionSite site) async {
    final response = await http.patch(
      Uri.parse(ApiConstants.getFullUrl('${ApiConstants.UpdateConstructionsite}${site.id}')),
      headers: ApiConstants.defaultHeaders,
      body: json.encode(site.toJson()),
    );
    if (response.statusCode == ApiConstants.statusOk) {
      return ConstructionSite.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to update site: ${response.body}');
  }

  // DELETE
  Future<void> deleteSite(String id) async {
    final response = await http.delete(
      Uri.parse(ApiConstants.getFullUrl('${ApiConstants.DeleteConstructionsite}$id')),
      headers: ApiConstants.defaultHeaders,
    );
    if (response.statusCode != ApiConstants.statusOk &&
        response.statusCode != ApiConstants.statusNoContent) {
      throw Exception('Failed to delete site: ${response.body}');
    }
  }
}