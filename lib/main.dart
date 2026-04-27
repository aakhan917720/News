import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'serivces/serivces.dart';
import 'package:flutter/material.dart';
import 'serivces/serivces.dart';

void main() {
  runApp(const NewsApp());
}

const kBlue     = Color(0xFF1A73E8);
const kBlueDark = Color(0xFF0D47A1);
const kBg       = Color(0xFFF4F6FA);
const kCard     = Colors.white;

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NewsFlash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: kBlue,
        scaffoldBackgroundColor: kBg,
        cardColor: kCard,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: kBlue,
        scaffoldBackgroundColor: const Color(0xFF111827),
        cardColor: const Color(0xFF1F2937),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NewsService           _service     = NewsService();
  final ScrollController      _scroll      = ScrollController();
  final TextEditingController _searchCtrl  = TextEditingController();
  final FocusNode             _searchFocus = FocusNode();

  List<Articles> _articles        = [];
  bool           _loading         = false;
  bool           _searching       = false;
  String         _error           = '';
  String         _selectedCategory = 'general';
  int            _page            = 1;
  bool           _hasMore         = true;
  bool           _loadingMore     = false;

  @override
  void initState() {
    super.initState();
    _loadNews(refresh: true);
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400 &&
        !_loadingMore && _hasMore && !_loading) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadNews({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      setState(() { _page = 1; _hasMore = true; _articles = []; _error = ''; });
    }
    setState(() => _loading = true);
    try {
      final result = await _service.getTopHeadlines(
        category: _selectedCategory,
        page: _page,
      );
      setState(() {
        _articles = result;
        _hasMore  = result.length == 20;
        _page     = 2;
        _loading  = false;
      });
    } catch (e) {
      setState(() {
        _error   = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final result = await _service.getTopHeadlines(
        category: _selectedCategory,
        page: _page,
      );
      setState(() {
        _articles.addAll(result);
        _hasMore     = result.length == 20;
        _page++;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) { _loadNews(refresh: true); return; }
    setState(() { _loading = true; _error = ''; _articles = []; _hasMore = false; });
    try {
      final result = await _service.searchNews(query);
      setState(() { _articles = result; _loading = false; });
    } catch (e) {
      setState(() {
        _error   = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _changeCategory(String cat) {
    if (_selectedCategory == cat) return;
    setState(() => _selectedCategory = cat);
    _searchCtrl.clear();
    setState(() => _searching = false);
    _loadNews(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          _buildCategoryBar(),
          Expanded(child: _buildBody()),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: _searching ? _buildSearchBar() : _buildTitleBar(),
    );
  }

  Widget _buildTitleBar() {
    return Row(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: kBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.flash_on, color: Colors.white, size: 22),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('NewsFlash',
            style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900,
              color: kBlue, letterSpacing: -0.5,
            )),
        Text('Stay informed · Stay ahead',
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ]),
      const Spacer(),
      IconButton(
        icon: const Icon(Icons.search_rounded),
        color: kBlue, iconSize: 26,
        onPressed: () {
          setState(() => _searching = true);
          Future.delayed(const Duration(milliseconds: 100),
                  () => _searchFocus.requestFocus());
        },
      ),
    ]);
  }

  Widget _buildSearchBar() {
    return Row(children: [
      Expanded(
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            decoration: InputDecoration(
              hintText: 'Search news...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: kBlue, size: 22),
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            ),
            onSubmitted: _search,
            textInputAction: TextInputAction.search,
          ),
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () {
          setState(() => _searching = false);
          _searchCtrl.clear();
          _loadNews(refresh: true);
        },
        child: Text('Cancel',
            style: TextStyle(
              color: kBlue,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            )),
      ),
    ]);
  }

  Widget _buildCategoryBar() {
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: NewsService.categories.length,
        itemBuilder: (_, i) {
          final cat      = NewsService.categories[i];
          final key      = cat['key']!;
          final icon     = cat['icon']!;
          final selected = key == _selectedCategory;
          return GestureDetector(
            onTap: () => _changeCategory(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? kBlue : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Row(children: [
                Text(icon, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 5),
                Text(
                  key[0].toUpperCase() + key.substring(1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : Colors.grey[600],
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _articles.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(strokeWidth: 2.5),
          SizedBox(height: 14),
          Text('Loading news...', style: TextStyle(color: Colors.grey)),
        ]),
      );
    }
    if (_error.isNotEmpty && _articles.isEmpty) return _buildError();
    if (_articles.isEmpty && !_loading) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📰', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('No articles found',
              style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ]),
      );
    }
    return RefreshIndicator(
      color: kBlue,
      onRefresh: () => _loadNews(refresh: true),
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _articles.length + (_loadingMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == _articles.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
            );
          }
          final article = _articles[i];
          return i == 0
              ? _HeroCard(article: article)
              : _ArticleCard(article: article, index: i);
        },
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi_off_rounded,
                size: 40, color: Colors.redAccent),
          ),
          const SizedBox(height: 16),
          Text('Oops!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              )),
          const SizedBox(height: 8),
          Text(_error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.5)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadNews(refresh: true),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HERO CARD
// ─────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final Articles article;
  const _HeroCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context, article),
      child: Container(
        height: 280,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(fit: StackFit.expand, children: [
            _NewsImage(url: article.urlToImage, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.9),
                  ],
                  stops: const [0.25, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      _SourceBadge(name: article.source?.name ?? 'Unknown'),
                      const Spacer(),
                      _TimeBadge(publishedAt: _parseDate(article.publishedAt)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      article.title ?? 'No Title',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 14, left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('TOP STORY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    )),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ARTICLE CARD
// ─────────────────────────────────────────────

class _ArticleCard extends StatelessWidget {
  final Articles article;
  final int      index;
  const _ArticleCard({required this.article, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context, article),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: SizedBox(
              width: 115, height: 115,
              child: _NewsImage(url: article.urlToImage, fit: BoxFit.cover),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (article.source?.name ?? 'Unknown').toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: kBlue,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    article.title ?? 'No Title',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.access_time_rounded,
                        size: 11, color: Colors.grey[400]),
                    const SizedBox(width: 3),
                    Text(
                      _timeAgo(_parseDate(article.publishedAt)),
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DETAIL SCREEN
// ─────────────────────────────────────────────

void _openDetail(BuildContext context, Articles article) {
  Navigator.push(context,
      MaterialPageRoute(builder: (_) => DetailScreen(article: article)));
}

class DetailScreen extends StatelessWidget {
  final Articles article;
  const DetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.share_rounded,
                    color: Colors.white, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Link: ${article.url ?? ''}'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ));
                },
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _NewsImage(url: article.urlToImage, fit: BoxFit.cover),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _SourceBadge(
                    name: article.source?.name ?? 'Unknown',
                    dark: true,
                  ),
                  const Spacer(),
                  Text(
                    _fullDate(_parseDate(article.publishedAt)),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ]),
                const SizedBox(height: 14),
                Text(
                  article.title ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
                if (article.author != null && article.author!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: kBlue.withValues(alpha: 0.1),
                      child: Icon(Icons.person_rounded, size: 15, color: kBlue),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        article.author!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ]),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
                if (article.description != null)
                  Text(
                    article.description!,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.65,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (article.content != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _cleanContent(article.content!),
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[300]
                          : Colors.grey[700],
                    ),
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Add url_launcher to open links'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Read Full Article',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────

class _NewsImage extends StatelessWidget {
  final String? url;
  final BoxFit  fit;
  const _NewsImage({this.url, required this.fit});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: Icon(Icons.article_rounded, size: 48, color: Colors.grey[400]),
      );
    }
    return Image.network(
      url!, fit: fit,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[300],
        child: Icon(Icons.broken_image_rounded,
            size: 40, color: Colors.grey[400]),
      ),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                  progress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: kBlue,
            ),
          ),
        );
      },
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String name;
  final bool   dark;
  const _SourceBadge({required this.name, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: dark ? kBlue : Colors.white24,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  final DateTime publishedAt;
  const _TimeBadge({required this.publishedAt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        _timeAgo(publishedAt),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// UTILITY FUNCTIONS
// ─────────────────────────────────────────────

DateTime _parseDate(String? dateStr) {
  return DateTime.tryParse(dateStr ?? '') ?? DateTime.now();
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24)   return '${diff.inHours}h ago';
  if (diff.inDays < 30)    return '${diff.inDays}d ago';
  return '${(diff.inDays / 30).floor()}mo ago';
}

String _fullDate(DateTime dt) {
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

String _cleanContent(String content) {
  return content
      .replaceAll(RegExp(r'\[.*?\]'), '')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .trim();
}