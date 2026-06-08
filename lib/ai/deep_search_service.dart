import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final deepSearchServiceProvider = Provider<DeepSearchService>((ref) {
  return DeepSearchService();
});

class DeepSearchService {
  static const String _duckDuckGoUrl = 'https://duckduckgo.com/html/';
  static const String _bingUrl = 'https://www.bing.com/search';
  static const String _googleUrl = 'https://www.google.com/search';

  Future<List<SearchResult>> search({
    required String query,
    int maxResults = 10,
    String engine = 'duckduckgo',
  }) async {
    try {
      switch (engine.toLowerCase()) {
        case 'duckduckgo':
          return await _searchDuckDuckGo(query, maxResults);
        case 'bing':
          return await _searchBing(query, maxResults);
        case 'google':
          return await _searchGoogle(query, maxResults);
        default:
          return await _searchDuckDuckGo(query, maxResults);
      }
    } catch (e) {
      print('Search error: $e');
      return [];
    }
  }

  Future<List<SearchResult>> _searchDuckDuckGo(String query, int maxResults) async {
    final response = await http.get(
      Uri.parse('https://duckduckgo.com/html/?q=${Uri.encodeComponent(query)}'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    );

    if (response.statusCode == 200) {
      return _parseDuckDuckGoResults(response.body, maxResults);
    }
    return [];
  }

  Future<List<SearchResult>> _searchBing(String query, int maxResults) async {
    final response = await http.get(
      Uri.parse('$_bingUrl?q=${Uri.encodeComponent(query)}'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    );

    if (response.statusCode == 200) {
      return _parseBingResults(response.body, maxResults);
    }
    return [];
  }

  Future<List<SearchResult>> _searchGoogle(String query, int maxResults) async {
    final response = await http.get(
      Uri.parse('$_googleUrl?q=${Uri.encodeComponent(query)}'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    );

    if (response.statusCode == 200) {
      return _parseGoogleResults(response.body, maxResults);
    }
    return [];
  }

  List<SearchResult> _parseDuckDuckGoResults(String html, int maxResults) {
    final results = <SearchResult>[];
    
    final titleRegex = RegExp(r'<a[^>]*class="result__a"[^>]*>([^<]+)</a>');
    final urlRegex = RegExp(r'href="([^"]+)"');
    final snippetRegex = RegExp(r'<a[^>]*class="result__snippet"[^>]*>([^<]+)</a>');
    
    final titleMatches = titleRegex.allMatches(html);
    final urlMatches = urlRegex.allMatches(html);
    final snippetMatches = snippetRegex.allMatches(html);
    
    for (int i = 0; i < titleMatches.length && i < maxResults; i++) {
      results.add(SearchResult(
        title: _cleanHtml(titleMatches.elementAt(i).group(1) ?? ''),
        url: _cleanHtml(urlMatches.elementAt(i).group(1) ?? ''),
        snippet: i < snippetMatches.length 
            ? _cleanHtml(snippetMatches.elementAt(i).group(1) ?? '') 
            : '',
        source: 'DuckDuckGo',
      ));
    }
    
    return results;
  }

  List<SearchResult> _parseBingResults(String html, int maxResults) {
    final results = <SearchResult>[];
    return results;
  }

  List<SearchResult> _parseGoogleResults(String html, int maxResults) {
    final results = <SearchResult>[];
    return results;
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  Future<ResearchReport> deepResearch({
    required String query,
    int iterations = 3,
  }) async {
    final allResults = <SearchResult>[];
    final visitedUrls = <String>{};
    
    String currentQuery = query;
    
    for (int i = 0; i < iterations; i++) {
      final results = await search(query: currentQuery, maxResults: 5);
      
      for (final result in results) {
        if (!visitedUrls.contains(result.url)) {
          visitedUrls.add(result.url);
          allResults.add(result);
        }
      }
      
      if (results.isNotEmpty) {
        currentQuery = '$query ${results.first.title}';
      }
    }
    
    return ResearchReport(
      query: query,
      results: allResults,
      summary: await _generateSummary(allResults),
      sources: visitedUrls.toList(),
    );
  }

  Future<String> _generateSummary(List<SearchResult> results) async {
    if (results.isEmpty) {
      return 'No results found.';
    }
    
    final combinedText = results
        .map((r) => '${r.title}: ${r.snippet}')
        .take(10)
        .join('\n\n');
    
    return 'Research summary based on ${results.length} sources:\n\n$combinedText';
  }
}

class SearchResult {
  final String title;
  final String url;
  final String snippet;
  final String source;
  final DateTime? publishedAt;

  SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    required this.source,
    this.publishedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'snippet': snippet,
      'source': source,
      'publishedAt': publishedAt?.toIso8601String(),
    };
  }
}

class ResearchReport {
  final String query;
  final List<SearchResult> results;
  final String summary;
  final List<String> sources;
  final DateTime generatedAt;

  ResearchReport({
    required this.query,
    required this.results,
    required this.summary,
    required this.sources,
  }) : generatedAt = DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'results': results.map((r) => r.toJson()).toList(),
      'summary': summary,
      'sources': sources,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}
