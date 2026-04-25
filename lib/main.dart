import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const NewsApp());
}

// ─────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────

class Source {
  final String? id;
  final String name;
  Source({this.id, required this.name});
  factory Source.fromJson(Map<String, dynamic> j) =>
      Source(id: j['id'], name: j['name'] ?? 'Unknown');
}

class Article {
  final Source source;
  final String? author;
  final String title;
  final String? description;
  final String url;
  final String? urlToImage;
  final DateTime publishedAt;
  final String? content;

  Article({
    required this.source,
    this.author,
    required this.title,
    this.description,
    required this.url,
    this.urlToImage,
    required this.publishedAt,
    this.content,
  });

  factory Article.fromJson(Map<String, dynamic> j) => Article(
    source: Source.fromJson(j['source']),
    author: j['author'],
    title: j['title'] ?? 'No Title',
    description: j['description'],
    url: j['url'] ?? '',
    urlToImage: j['urlToImage'],
    publishedAt: DateTime.tryParse(j['publishedAt'] ?? '') ?? DateTime.now(),
    content: j['content'],
  );
}

// ─────────────────────────────────────────────
// API SERVICE
// ─────────────────────────────────────────────

class NewsService {
  // ✅ Get FREE key at: https://newsapi.org/register
  static const String apiKey = 'YOUR_API_KEY_HERE';
  static const String baseUrl = 'https://newsapi.org/v2';

  static const List<String> categories = [
    'general', 'technology', 'business',
    'entertainment', 'health', 'science', 'sports'
  ];

  Future<List<Article>> getTopHeadlines({
    String category = 'general',
    int page = 1,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/top-headlines?apiKey=$apiKey&country=us&category=$category&page=$page&pageSize=20',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List articles = data['articles'] ?? [];
      return articles
          .map((a) => Article.fromJson(a))
          .where((a) => a.title != '[Removed]' && a.url.isNotEmpty)
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('Invalid API Key. Get one at newsapi.org');
    } else {
      throw Exception('Failed to load news: ${response.statusCode}');
    }
  }

  Future<List<Article>> searchNews(String query) async {
    final uri = Uri.parse(
      '$baseUrl/everything?apiKey=$apiKey&q=$query&language=en&sortBy=publishedAt&pageSize=20',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List articles = data['articles'] ?? [];
      return articles
          .map((a) => Article.fromJson(a))
          .where((a) => a.title != '[Removed]' && a.url.isNotEmpty)
          .toList();
    } else {
      throw Exception('Search failed: ${response.statusCode}');
    }
  }
}

// ─────────────────────────────────────────────
// APP
// ─────────────────────────────────────────────

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NewsFlash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NewsService _service = NewsService();
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  List<Article> _articles = [];
  bool _loading = false;
  bool _searching = false;
  String _error = '';
  String _category = 'general';
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadNews(refresh: true);
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        _loadNews();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNews({bool refresh = false}) async {
    if (_loading || !_hasMore) return;
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _articles = [];
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final result = await _service.getTopHeadlines(
        category: _category,
        page: _page,
      );
      setState(() {
        _articles.addAll(result);
        _hasMore = result.length == 20;
        _page++;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      _loadNews(refresh: true);
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
      _articles = [];
    });
    try {
      final result = await _service.searchNews(query);
      setState(() {
        _articles = result;
        _hasMore = false;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _changeCategory(String cat) {
    if (_category == cat) return;
    setState(() => _category = cat);
    _loadNews(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCategories(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: _searching
          ? Row(children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search news...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: _search,
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() => _searching = false);
            _searchCtrl.clear();
            _loadNews(refresh: true);
          },
          child: const Text('Cancel'),
        ),
      ])
          : Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NewsFlash',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.blue[700],
                  )),
              Text('Stay informed',
                  style:
                  TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _searching = true),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: NewsService.categories.length,
        itemBuilder: (_, i) {
          final cat = NewsService.categories[i];
          final selected = cat == _category;
          return GestureDetector(
            onTap: () => _changeCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? Colors.blue[700] : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                cat[0].toUpperCase() + cat.substring(1),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _articles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty && _articles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadNews(refresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadNews(refresh: true),
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: _articles.length + (_hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == _articles.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final article = _articles[i];
          return i == 0
              ? _HeroCard(article: article)
              : _ListCard(article: article);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HERO CARD (First Article)
// ─────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final Article article;
  const _HeroCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DetailScreen(article: article))),
      child: Container(
        height: 260,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              article.urlToImage != null
                  ? Image.network(
                article.urlToImage!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey[300]),
              )
                  : Container(color: Colors.grey[300]),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          article.source.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        article.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LIST CARD
// ─────────────────────────────────────────────

class _ListCard extends StatelessWidget {
  final Article article;
  const _ListCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final diff = DateTime.now().difference(article.publishedAt);
    final timeLabel = diff.inMinutes < 60
        ? '${diff.inMinutes}m ago'
        : diff.inHours < 24
        ? '${diff.inHours}h ago'
        : '${diff.inDays}d ago';

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DetailScreen(article: article))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: article.urlToImage != null
                  ? Image.network(
                article.urlToImage!,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 110,
                  height: 110,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported,
                      color: Colors.grey),
                ),
              )
                  : Container(
                width: 110,
                height: 110,
                color: Colors.grey[200],
                child:
                const Icon(Icons.article, color: Colors.grey),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.source.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue[600],
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DETAIL SCREEN
// ─────────────────────────────────────────────

class DetailScreen extends StatelessWidget {
  final Article article;
  const DetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child:
                const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: article.urlToImage != null
                  ? Image.network(
                article.urlToImage!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey),
              )
                  : Container(color: Colors.grey),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.source.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue[700],
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  if (article.author != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'By ${article.author}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const Divider(height: 28),
                  if (article.description != null)
                    Text(
                      article.description!,
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                  if (article.content != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      article.content!
                          .replaceAll(RegExp(r'\[.*?\]'), '')
                          .trim(),
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.65,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '… Read full article at source',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                // URL Launcher — add url_launcher package for this to work
                // launchUrl(Uri.parse(article.url));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('URL: ${article.url}'),
                    action: SnackBarAction(label: 'OK', onPressed: () {}),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Read Full Article'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}