import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:serik/l10n/app_localization.dart';
import 'package:serik/model/rental_model.dart';
import 'package:serik/pages/login_page.dart';
import 'package:serik/providers/auth_provider.dart';
import 'package:serik/providers/theme_provider.dart';
import 'package:serik/screen/rental_detail_screen.dart';
import 'package:serik/services/api_services.dart';
import 'package:video_player/video_player.dart';

/// Model ya comment
class VideoComment {
  final String id;
  final String username;
  final String userAvatar;
  final String text;
  final DateTime timestamp;
  int likes;
  bool isLiked;
  final List<VideoComment> replies;
  final String userId;

  VideoComment({
    required this.id,
    required this.username,
    required this.userAvatar,
    required this.text,
    required this.timestamp,
    this.likes = 0,
    this.isLiked = false,
    this.replies = const [],
    this.userId = '',
  });

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo';
    } else if (diff.inDays > 7) {
      return '${(diff.inDays / 7).floor()}w';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'sasa hivi';
    }
  }
}

class VideoFeedItem {
  final RentalSpot spot;
  final String videoId; // Sasa ni URL halisi ya video
  final String videoUrl;
  final String? thumbnailUrl;
  int likes;
  int commentsCount;
  bool liked;
  List<VideoComment> comments;
  bool isLoadingComments;

  VideoFeedItem({
    required this.spot,
    required this.videoId,
    required this.videoUrl,
    this.thumbnailUrl,
    this.likes = 0,
    this.commentsCount = 0,
    this.liked = false,
    this.comments = const [],
    this.isLoadingComments = false,
  });
}

class VideoFeedPage extends StatefulWidget {
  final bool isVisible;

  const VideoFeedPage({super.key, this.isVisible = true});

  @override
  State<VideoFeedPage> createState() => _VideoFeedPageState();
}

class _VideoFeedPageState extends State<VideoFeedPage> {
  final PageController _pageController = PageController();
  final List<VideoFeedItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentIndex = 0;
  bool _isRouteVisible = true;

  // Comment section state
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  // ============================================================
  // LOAD VIDEOS - FIXED: Use videoUrl as videoId
  // ============================================================
  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final feedItems = await ApiService.getVideoFeed();
      final items = <VideoFeedItem>[];

      for (final json in feedItems) {
        final videos = (json['videos'] as List?) ?? [];
        if (videos.isEmpty) continue;

        final spot = RentalSpot.fromVideoFeedJson(json);

        for (var index = 0; index < spot.videos.length; index++) {
          final videoUrl = spot.videos[index];

          // ✅ FIX: Use the actual video URL as ID
          // Backend will find video by ID or URL
          final videoId = videoUrl;

          // Get real like status from backend
          Map<String, dynamic>? likeStatus;
          try {
            likeStatus = await ApiService.getVideoLikeStatus(videoId);
          } catch (e) {
            debugPrint('⚠️ Could not get like status: $e');
          }

          final isLiked = likeStatus?['is_liked'] ?? false;
          final likesCount = likeStatus?['likes_count'] ?? 0;

          items.add(
            VideoFeedItem(
              spot: spot,
              videoId: videoId, // ✅ Now using URL as ID
              videoUrl: videoUrl,
              thumbnailUrl: spot.videoThumbnails.length > index
                  ? spot.videoThumbnails[index]
                  : null,
              likes: likesCount,
              commentsCount: 0,
              liked: isLiked,
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading video feed: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'error';
      });
    }
  }

  // ============================================================
  // PARSE COMMENTS FROM API RESPONSE
  // ============================================================
  List<VideoComment> _parseCommentsFromApi(List<dynamic> data) {
    return data.map((json) {
      final user = json['user'] ?? {};
      final firstName = user['firstName'] ?? user['first_name'] ?? '';
      final lastName = user['lastName'] ?? user['last_name'] ?? '';
      final fullName = '$firstName $lastName'.trim();

      return VideoComment(
        id: json['id']?.toString() ?? '',
        userId: user['id']?.toString() ?? '',
        username: fullName.isNotEmpty ? fullName : 'Mtumiaji',
        userAvatar:
            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(fullName)}&background=4CAF50&color=fff&size=100',
        text: json['content'] ?? '',
        timestamp: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        likes: json['likes_count'] ?? 0,
        isLiked: json['is_liked'] ?? false,
        replies:
            (json['replies'] as List?)?.map((reply) {
              final replyUser = reply['user'] ?? {};
              final replyFirstName =
                  replyUser['firstName'] ?? replyUser['first_name'] ?? '';
              final replyLastName =
                  replyUser['lastName'] ?? replyUser['last_name'] ?? '';
              final replyFullName = '$replyFirstName $replyLastName'.trim();

              return VideoComment(
                id: reply['id']?.toString() ?? '',
                userId: replyUser['id']?.toString() ?? '',
                username: replyFullName.isNotEmpty ? replyFullName : 'Mtumiaji',
                userAvatar:
                    'https://ui-avatars.com/api/?name=${Uri.encodeComponent(replyFullName)}&background=4CAF50&color=fff&size=100',
                text: reply['content'] ?? '',
                timestamp: reply['created_at'] != null
                    ? DateTime.parse(reply['created_at'])
                    : DateTime.now(),
                likes: reply['likes_count'] ?? 0,
                isLiked: reply['is_liked'] ?? false,
                replies: [],
              );
            }).toList() ??
            [],
      );
    }).toList();
  }

  // ============================================================
  // TOGGLE VIDEO LIKE WITH BACKEND
  // ============================================================
  Future<void> _toggleLike(VideoFeedItem item) async {
    if (!_isLoggedIn) {
      _showLoginPrompt();
      return;
    }

    // Optimistic update
    setState(() {
      item.liked = !item.liked;
      item.likes += item.liked ? 1 : -1;
    });

    try {
      final result = await ApiService.toggleVideoLike(item.videoId);
      if (result == null) {
        // Revert on error
        setState(() {
          item.liked = !item.liked;
          item.likes += item.liked ? 1 : -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hitilafu kubadilisha like'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Revert on error
      setState(() {
        item.liked = !item.liked;
        item.likes += item.liked ? 1 : -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hitilafu: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ============================================================
  // TOGGLE COMMENT LIKE WITH BACKEND
  // ============================================================
  Future<void> _toggleCommentLike(
    VideoComment comment,
    VideoFeedItem item,
  ) async {
    if (!_isLoggedIn) return;

    // Optimistic update
    setState(() {
      comment.isLiked = !comment.isLiked;
      comment.likes += comment.isLiked ? 1 : -1;
    });

    try {
      final result = await ApiService.toggleCommentLike(comment.id);
      if (result == null) {
        // Revert on error
        setState(() {
          comment.isLiked = !comment.isLiked;
          comment.likes += comment.isLiked ? 1 : -1;
        });
      }
    } catch (e) {
      // Revert on error
      setState(() {
        comment.isLiked = !comment.isLiked;
        comment.likes += comment.isLiked ? 1 : -1;
      });
    }
  }

  // ============================================================
  // SHOW COMMENTS - FETCH FROM BACKEND
  // ============================================================
  void _showComments(VideoFeedItem item) async {
    if (!_isLoggedIn) {
      _showLoginPrompt();
      return;
    }

    // Mark as loading
    setState(() {
      item.isLoadingComments = true;
    });

    // Fetch fresh comments from backend
    try {
      final commentsData = await ApiService.getVideoComments(item.videoId);
      final comments = _parseCommentsFromApi(commentsData);

      setState(() {
        item.comments = comments;
        item.commentsCount = comments.length;
        item.isLoadingComments = false;
      });
    } catch (e) {
      setState(() {
        item.isLoadingComments = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hitilafu kupata comments: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    _commentController.clear();
    _commentFocusNode.requestFocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildCommentSheet(item),
    ).then((_) {
      _commentFocusNode.unfocus();
      setState(() {});
    });
  }

  // ============================================================
  // BUILD COMMENT SHEET
  // ============================================================
  Widget _buildCommentSheet(VideoFeedItem item) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final textColor = colors.onSurface;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      l10n.comments(item.commentsCount),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: textColor),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.outlineVariant),

              // Comments list
              Expanded(
                child: item.isLoadingComments
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: item.comments.length,
                        itemBuilder: (context, index) {
                          final comment = item.comments[index];
                          return _buildCommentTile(comment, item);
                        },
                      ),
              ),

              // Comment input
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(top: BorderSide(color: colors.outlineVariant)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(
                        'https://ui-avatars.com/api/?name=Wewe&background=0F8B61&color=fff&size=100',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _commentFocusNode,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: l10n.tr(
                            'Andika maoni yako...',
                            en: 'Write your comment...',
                          ),
                          hintStyle: TextStyle(color: colors.onSurfaceVariant),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: colors.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _isSubmittingComment
                          ? null
                          : () => _sendComment(item),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isSubmittingComment
                              ? colors.outline
                              : colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: _isSubmittingComment
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD COMMENT TILE
  // ============================================================
  Widget _buildCommentTile(VideoComment comment, VideoFeedItem item) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(comment.userAvatar),
                onBackgroundImageError: (_, __) {},
                child: Text(
                  comment.username.isNotEmpty
                      ? comment.username[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.username,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          comment.timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.text,
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleCommentLike(comment, item),
                          child: Row(
                            children: [
                              Icon(
                                comment.isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 16,
                                color: comment.isLiked
                                    ? Colors.redAccent
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                comment.likes > 0 ? '${comment.likes}' : '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _showReplyInput(comment, item),
                          child: Text(
                            'Jibu',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Replies
                    if (comment.replies.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...comment.replies.map(
                        (reply) => _buildReplyTile(reply, item),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD REPLY TILE
  // ============================================================
  Widget _buildReplyTile(VideoComment reply, VideoFeedItem item) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(left: 48, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(reply.userAvatar),
                onBackgroundImageError: (_, __) {},
                child: Text(
                  reply.username.isNotEmpty
                      ? reply.username[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          reply.username,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          reply.timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reply.text,
                      style: TextStyle(fontSize: 13, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleCommentLike(reply, item),
                          child: Row(
                            children: [
                              Icon(
                                reply.isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 14,
                                color: reply.isLiked
                                    ? Colors.redAccent
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                reply.likes > 0 ? '${reply.likes}' : '',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _showReplyInput(reply, item),
                          child: Text(
                            'Jibu',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  // ============================================================
  // SHOW REPLY INPUT
  // ============================================================
  void _showReplyInput(VideoComment parentComment, VideoFeedItem item) {
    _commentController.clear();
    _commentFocusNode.requestFocus();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jibu Comment'),
        content: TextField(
          controller: _commentController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Andika jibu lako...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          FilledButton(
            onPressed: () {
              final text = _commentController.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(context);
                _sendReply(parentComment.id, text, item);
              }
            },
            child: const Text('Tuma Jibu'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEND REPLY TO BACKEND
  // ============================================================
  Future<void> _sendReply(
    String parentId,
    String content,
    VideoFeedItem item,
  ) async {
    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final result = await ApiService.createComment(
        videoId: item.videoId,
        houseId: item.spot.id,
        content: content,
        parentId: parentId,
      );

      if (result != null) {
        // Refresh comments
        final commentsData = await ApiService.getVideoComments(item.videoId);
        final comments = _parseCommentsFromApi(commentsData);

        setState(() {
          item.comments = comments;
          item.commentsCount = comments.length;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jibu limetumwa!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hitilafu kutuma jibu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hitilafu: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isSubmittingComment = false;
      });
    }
  }

  // ============================================================
  // SEND COMMENT TO BACKEND
  // ============================================================
  Future<void> _sendComment(VideoFeedItem item) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final result = await ApiService.createComment(
        videoId: item.videoId,
        houseId: item.spot.id,
        content: text,
      );

      if (result != null) {
        final newComment = VideoComment(
          id: result['id']?.toString() ?? '',
          userId: result['user']?['id']?.toString() ?? '',
          username: 'Wewe',
          userAvatar:
              'https://ui-avatars.com/api/?name=Wewe&background=4CAF50&color=fff&size=100',
          text: result['content'] ?? text,
          timestamp: DateTime.now(),
          likes: 0,
          isLiked: false,
          replies: [],
        );

        setState(() {
          item.comments.insert(0, newComment);
          item.commentsCount = item.comments.length;
        });

        _commentController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment imetumwa!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hitilafu kutuma comment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hitilafu: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isSubmittingComment = false;
      });
    }
  }

  // ============================================================
  // SHARE VIDEO
  // ============================================================
  Future<void> _share(VideoFeedItem item) async {
    if (!_isLoggedIn) {
      _showLoginPrompt();
      return;
    }
    final text =
        '${item.spot.brandName}\n${item.spot.formattedPrice}\n${item.spot.getShortAddress()}\n${item.videoUrl}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.videoLinkCopied)));
  }

  // ============================================================
  // OPEN DETAILS
  // ============================================================
  Future<void> _openDetails(VideoFeedItem item) async {
    if (!_isLoggedIn) {
      _showLoginPrompt();
      return;
    }
    setState(() => _isRouteVisible = false);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RentalDetailScreen(spot: item.spot),
      ),
    );
    if (mounted) setState(() => _isRouteVisible = true);
  }

  bool get _isLoggedIn =>
      Provider.of<AuthProvider>(context, listen: false).isLoggedIn;

  bool get _canPlayCurrentVideo => widget.isVisible && _isRouteVisible;

  // ============================================================
  // SHOW LOGIN PROMPT
  // ============================================================
  void _showLoginPrompt() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.loginRequired),
        content: Text(l10n.loginRequiredDetails),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.later),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (!mounted) return;
              setState(() => _isRouteVisible = false);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
              if (mounted) setState(() => _isRouteVisible = true);
            },
            icon: const Icon(Icons.login_rounded),
            label: Text(l10n.signIn),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Provider.of<AuthProvider>(context).isLoggedIn;
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final backgroundColor = colors.surface;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: colors.primary),
        ),
      );
    }

    if (_errorMessage != null || _items.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.video_library_outlined,
                  size: 72,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage == 'error'
                      ? l10n.videoFeedError
                      : l10n.videoFeedEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurface, fontSize: 16),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadVideos,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _items.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final item = _items[index];
              return _VideoFeedTile(
                key: ValueKey(item.videoUrl),
                item: item,
                isActive: index == _currentIndex && _canPlayCurrentVideo,
                onLike: () => _toggleLike(item),
                onComment: () => _showComments(item),
                onShare: () => _share(item),
                onOpenDetails: () => _openDetails(item),
                isLoggedIn: isLoggedIn,
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.play_circle_rounded, color: colors.primary),
                    const SizedBox(width: 8),
                    Text(
                      l10n.videoFeedTitle,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _loadVideos,
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: colors.onSurface,
                      ),
                      tooltip: l10n.retry,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoFeedTile extends StatefulWidget {
  final VideoFeedItem item;
  final bool isActive;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onOpenDetails;
  final bool isLoggedIn;

  const _VideoFeedTile({
    super.key,
    required this.item,
    required this.isActive,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onOpenDetails,
    required this.isLoggedIn,
  });

  @override
  State<_VideoFeedTile> createState() => _VideoFeedTileState();
}

class _VideoFeedTileState extends State<_VideoFeedTile>
    with WidgetsBindingObserver {
  late final VideoPlayerController _controller;
  bool _isReady = false;
  bool _isMuted = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.item.videoUrl),
    );
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      if (!mounted) return;
      setState(() => _isReady = true);
      _syncPlayback();
    } catch (e) {
      debugPrint('❌ Video initialization error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void didUpdateWidget(covariant _VideoFeedTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isReady || _hasError) return;
    _syncPlayback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isReady || _hasError) return;
    if (state == AppLifecycleState.resumed) {
      _syncPlayback();
    } else {
      _controller.pause();
    }
  }

  void _syncPlayback() {
    if (widget.isActive && !_controller.value.isPlaying) {
      _controller.play();
    } else if (!widget.isActive && _controller.value.isPlaying) {
      _controller.pause();
    }
  }

  void _togglePlayback() {
    if (!_isReady || _hasError || !widget.isActive) return;
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _toggleMute() {
    if (!_isReady || _hasError) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _togglePlayback,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),

          if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.white60, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Video haipatikani',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            )
          else if (_isReady)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            )
          else if (widget.item.thumbnailUrl != null)
            Image.network(
              widget.item.thumbnailUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.grey[900]);
              },
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.78),
                ],
              ),
            ),
          ),

          if (_isReady && !_controller.value.isPlaying && !_hasError)
            const Center(
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 86,
              ),
            ),

          Positioned(
            right: 12,
            bottom: 105,
            child: Column(
              children: [
                _ActionButton(
                  icon: item.liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: item.likes > 0 ? '${item.likes}' : '',
                  color: item.liked ? Colors.redAccent : Colors.white,
                  onTap: widget.onLike,
                ),
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: item.commentsCount > 0 ? '${item.commentsCount}' : '',
                  onTap: widget.onComment,
                ),
                _ActionButton(
                  icon: Icons.share_rounded,
                  label: l10n.share,
                  onTap: widget.onShare,
                ),
                _ActionButton(
                  icon: _isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  label: _isMuted ? l10n.mute : l10n.sound,
                  onTap: _toggleMute,
                ),
              ],
            ),
          ),

          Positioned(
            left: 16,
            right: 86,
            bottom: 34,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isLoggedIn) ...[
                  Text(
                    item.spot.brandName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.spot.formattedPrice} • ${item.spot.getShortAddress()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.loginForHouseInfo,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: widget.onOpenDetails,
                  icon: Icon(
                    widget.isLoggedIn
                        ? Icons.home_work_outlined
                        : Icons.login_rounded,
                    size: 18,
                  ),
                  label: Text(
                    widget.isLoggedIn ? l10n.viewDetails : l10n.loginForMore,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    backgroundColor: Colors.black.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          ),

          if (_isReady && !_hasError)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: colors.primary,
                  bufferedColor: Colors.white54,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.22),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.22),
                ),
              ),
              child: Icon(icon, color: color, size: 27),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
