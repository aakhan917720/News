import 'dart:convert';
import 'package:http/http.dart' as http;

NewsApi newsApiFromJson(String str) => NewsApi.fromJson(json.decode(str));

class NewsApi {
  NewsApi({String? status, num? totalResults, List<Articles>? articles}) {
    _status = status;
    _totalResults = totalResults;
    _articles = articles;
  }

  NewsApi.fromJson(dynamic json) {
    _status = json['status'];
    _totalResults = json['totalResults'];
    if (json['articles'] != null) {
      _articles = [];
      json['articles'].forEach((v) {
        _articles?.add(Articles.fromJson(v));
      });
    }
  }

  String? _status;
  num? _totalResults;
  List<Articles>? _articles;

  String? get status => _status;
  num? get totalResults => _totalResults;
  List<Articles>? get articles => _articles;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['totalResults'] = _totalResults;
    if (_articles != null) {
      map['articles'] = _articles?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Articles {
  Articles({
    Source? source,
    String? author,
    String? title,
    String? description,
    String? url,
    String? urlToImage,
    String? publishedAt,
    String? content,
  }) {
    _source = source;
    _author = author;
    _title = title;
    _description = description;
    _url = url;
    _urlToImage = urlToImage;
    _publishedAt = publishedAt;
    _content = content;
  }

  Articles.fromJson(dynamic json) {
    _source = json['source'] != null ? Source.fromJson(json['source']) : null;
    _author = json['author'];
    _title = json['title'];
    _description = json['description'];
    _url = json['url'];
    _urlToImage = json['urlToImage'];
    _publishedAt = json['publishedAt'];
    _content = json['content'];
  }

  Source? _source;
  String? _author;
  String? _title;
  String? _description;
  String? _url;
  String? _urlToImage;
  String? _publishedAt;
  String? _content;

  Source? get source => _source;
  String? get author => _author;
  String? get title => _title;
  String? get description => _description;
  String? get url => _url;
  String? get urlToImage => _urlToImage;
  String? get publishedAt => _publishedAt;
  String? get content => _content;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_source != null) map['source'] = _source?.toJson();
    map['author'] = _author;
    map['title'] = _title;
    map['description'] = _description;
    map['url'] = _url;
    map['urlToImage'] = _urlToImage;
    map['publishedAt'] = _publishedAt;
    map['content'] = _content;
    return map;
  }
}

class Source {
  Source({dynamic id, String? name}) {
    _id = id;
    _name = name;
  }

  Source.fromJson(dynamic json) {
    _id = json['id'];
    _name = json['name'];
  }

  dynamic _id;
  String? _name;

  dynamic get id => _id;
  String? get name => _name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['name'] = _name;
    return map;
  }
}

// ─────────────────────────────────────────────
// NEWS SERVICE
// ─────────────────────────────────────────────

class NewsService {
  static const String apiKey  = '12328fe86128405bbb21990661fab270';
  static const String baseUrl = 'https://newsapi.org/v2';

  static const List<Map<String, String>> categories = [
    {'key': 'general',       'icon': '🌍'},
    {'key': 'technology',    'icon': '💻'},
    {'key': 'business',      'icon': '💼'},
    {'key': 'entertainment', 'icon': '🎬'},
    {'key': 'health',        'icon': '🏥'},
    {'key': 'science',       'icon': '🔬'},
    {'key': 'sports',        'icon': '⚽'},
  ];

  // ── Category News ──────────────────────────
  Future<List<Articles>> getTopHeadlines({
    String category = 'general',
    String country  = 'pk',
    int    page     = 1,
    int    pageSize = 20,
  }) async {

    final Map<String, String> categoryQueries = {
      'general':       'world news today',
      'technology':    'technology',
      'business':      'business finance',
      'entertainment': 'entertainment celebrity',
      'health':        'health medical',
      'science':       'science research',
      'sports':        'sports',
    };

    final query = categoryQueries[category] ?? category;

    final uri = Uri.parse(
      '$baseUrl/everything'
          '?apiKey=$apiKey'
          '&q=${Uri.encodeComponent(query)}'
          '&from=2026-03-27'
          '&sortBy=publishedAt'
          '&language=en'
          '&page=$page'
          '&pageSize=$pageSize',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final newsApi = newsApiFromJson(response.body);
        return newsApi.articles?.where((a) =>
        a.title      != null &&
            a.title      != '[Removed]' &&
            a.url        != null &&
            a.urlToImage != null
        ).toList() ?? [];

      } else if (response.statusCode == 401) {
        throw Exception('❌ Invalid API Key');
      } else if (response.statusCode == 429) {
        throw Exception('⚠️ Rate limit — 100 req/day');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('⏱️ Timeout');
      }
      rethrow;
    }
  }

  // ── Search News ────────────────────────────
  Future<List<Articles>> searchNews(String query, {int pageSize = 20}) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(
      '$baseUrl/everything'
          '?apiKey=$apiKey'
          '&q=${Uri.encodeComponent(query)}'
          '&from=2026-03-27'
          '&sortBy=publishedAt'
          '&language=en'
          '&pageSize=$pageSize',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final newsApi = newsApiFromJson(response.body);
        return newsApi.articles?.where((a) =>
        a.title      != null &&
            a.title      != '[Removed]' &&
            a.url        != null &&
            a.urlToImage != null
        ).toList() ?? [];
      } else {
        throw Exception('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('⏱️ Timeout');
      }
      rethrow;
    }
  }
}