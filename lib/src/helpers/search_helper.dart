class SearchHelper {
  static List<SearchMatch> findMatches({
    required String text,
    required String query,
  }) {
    if (query.isEmpty || text.isEmpty) {
      return [];
    }

    final searchText =  text.toLowerCase();
    final searchQuery = query.toLowerCase();
    
    final matches = <SearchMatch>[];
    var startIndex = 0;

    while (true) {
      final index = searchText.indexOf(searchQuery, startIndex);
      if (index == -1) break;

      matches.add(SearchMatch(
        start: index,
        end: index + searchQuery.length,
      ));
      startIndex = index + 1;
    }

    return matches;
  }
}

class SearchMatch {
  final int start;
  final int end;

  SearchMatch({required this.start, required this.end});

  int get length => end - start;

  @override
  String toString() => 'SearchMatch(start: $start, end: $end)';
}

