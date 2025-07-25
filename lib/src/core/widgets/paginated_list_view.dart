import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';

class PaginatedListView<T> extends StatefulWidget {
  final Stream<PaginatedResult<T>> Function(int page, int limit) loadData;
  final Widget Function(T item, int index) itemBuilder;
  final Widget Function()? emptyBuilder;
  final Widget Function(String error)? errorBuilder;
  final int pageSize;
  final String? searchQuery;
  final EdgeInsetsGeometry? padding;

  const PaginatedListView({
    super.key,
    required this.loadData,
    required this.itemBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.pageSize = 50,
    this.searchQuery,
    this.padding,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<PaginatedResult<T>>? _subscription;
  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  int _currentPage = 1;
  String? _lastSearchQuery;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void didUpdateWidget(PaginatedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _lastSearchQuery) {
      _resetAndReload();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  void _loadInitialData() {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    _subscription?.cancel();
    _subscription = widget.loadData(1, widget.pageSize).listen(
      (result) {
        if (mounted) {
          setState(() {
            _items.clear();
            _items.addAll(result.items);
            _hasMore = result.hasMore;
            _currentPage = 1;
            _lastSearchQuery = widget.searchQuery;
            _isLoading = false;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      },
    );
  }

  void _loadMoreData() {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    _subscription?.cancel();
    _subscription =
        widget.loadData(_currentPage + 1, widget.pageSize).listen(
      (result) {
        if (mounted) {
          setState(() {
            _items.addAll(result.items);
            _hasMore = result.hasMore;
            _currentPage++;
            _isLoading = false;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      },
    );
  }

  void _resetAndReload() {
    _items.clear();
    _currentPage = 1;
    _hasMore = true;
    _error = null;
    _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items.isEmpty) {
      return widget.errorBuilder?.call(_error!) ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(FluentIcons.error, size: 48),
                const SizedBox(height: 16),
                Text('Error: $_error'),
                const SizedBox(height: 16),
                Button(
                  onPressed: _resetAndReload,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
    }

    if (_items.isEmpty && !_isLoading) {
      return widget.emptyBuilder?.call() ??
          const Center(
            child: Text('No items found'),
          );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: ProgressRing()),
          );
        }

        return widget.itemBuilder(_items[index], index);
      },
    );
  }
}

class PaginatedResult<T> {
  final List<T> items;
  final bool hasMore;
  final int totalCount;

  const PaginatedResult({
    required this.items,
    required this.hasMore,
    required this.totalCount,
  });
}
