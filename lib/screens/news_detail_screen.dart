// lib/screens/news_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_model.dart';
import '../models/comment_model.dart';
import '../view_models/news_view_model.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsArticle article;
  const NewsDetailScreen({super.key, required this.article});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final FocusNode _commentFocusNode = FocusNode();
  
  // --- Переменные состояния экрана ---
  List<Comment> _comments = [];
  Set<String> _likedCommentIds = {};
  bool _isLoadingComments = true;
  
  // Состояние для ответа на комментарий
  String? _replyingToCommentId;
  String? _replyingToUserName;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  // --- ЛОГИКА ---

  Future<void> _loadInitialData() async {
    setState(() { _isLoadingComments = true; });

    final newsViewModel = Provider.of<NewsViewModel>(context, listen: false);
    newsViewModel.incrementViewCount(widget.article.id);
    
    // Загружаем данные параллельно
    final results = await Future.wait([
      newsViewModel.fetchComments(widget.article.id),
      newsViewModel.fetchLikedCommentIds(widget.article.id),
    ]);
    
    if (mounted) {
      setState(() {
        // --- ИСПРАВЛЕНИЕ ЗДЕСЬ ---
        // Явно приводим (кастуем) типы перед присвоением
        _comments = results[0] as List<Comment>;
        _likedCommentIds = results[1] as Set<String>;
        _isLoadingComments = false;
      });
    }
}

  void _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final newsViewModel = Provider.of<NewsViewModel>(context, listen: false);
    
    await newsViewModel.addComment(
      widget.article.id,
      _commentController.text.trim(),
      parentId: _replyingToCommentId,
      parentUserName: _replyingToUserName,
    );

    _commentController.clear();
    _cancelReply();
  }

  void _handleLikeToggle(Comment comment) {
    final viewModel = Provider.of<NewsViewModel>(context, listen: false);
    final bool isCurrentlyLiked = _likedCommentIds.contains(comment.id);
    
    // Мгновенно обновляем интерфейс (Оптимистичное обновление)
    setState(() {
      if (isCurrentlyLiked) {
        _likedCommentIds.remove(comment.id);
        comment.likeCount--;
      } else {
        _likedCommentIds.add(comment.id);
        comment.likeCount++;
      }
    });

    // Отправляем запрос на сервер в фоновом режиме
    viewModel.toggleCommentLike(widget.article.id, comment.id);
  }

  void _startReply(Comment comment) {
    setState(() {
      _replyingToCommentId = comment.id;
      _replyingToUserName = comment.userName;
    });
    FocusScope.of(context).requestFocus(_commentFocusNode);
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
    _commentFocusNode.unfocus();
  }

  // --- ИНТЕРФЕЙС ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article.category.isNotEmpty ? widget.article.category : "Жаңалық"),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildArticleContent(),
                _buildCommentsSection(),
              ],
            ),
          ),
          _buildCommentInputField(),
        ],
      ),
    );
  }
  
  SliverToBoxAdapter _buildArticleContent() {
    final formattedDate = DateFormat('dd MMMM, HH:mm', 'ru').format(widget.article.createdAt.toDate());
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.article.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(formattedDate, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 16),
            if (widget.article.imageUrl.isNotEmpty)
              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(widget.article.imageUrl, width: double.infinity, fit: BoxFit.cover)),
            const SizedBox(height: 24),
            Text(widget.article.content, style: const TextStyle(fontSize: 16, height: 1.5)),
            const Divider(height: 40),
            Text('Комментарии (${widget.article.commentCount})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    if (_isLoadingComments) {
      return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())));
    }
    if (_comments.isEmpty) {
      return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Text('Комментариев пока нет.'))));
    }

    final topLevelComments = _comments.where((c) => c.parentId == null).toList();
    final replies = _comments.where((c) => c.parentId != null).toList();
    
    final Map<String, List<Comment>> repliesMap = {};
    for (final reply in replies) {
      repliesMap.putIfAbsent(reply.parentId!, () => []).add(reply);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final comment = topLevelComments[index];
          final commentReplies = repliesMap[comment.id] ?? [];
          return _buildCommentTree(comment, commentReplies);
        },
        childCount: topLevelComments.length,
      ),
    );
  }
  
  Widget _buildCommentTree(Comment parentComment, List<Comment> replies) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCommentTile(parentComment, isReply: false),
          if (replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: replies.map((reply) => _buildCommentTile(reply, isReply: true)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(Comment comment, {required bool isReply}) {
    final mentionStyle = TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold);
    final regularStyle = const TextStyle(fontSize: 16, color: Colors.black87);
    final bool isLiked = _likedCommentIds.contains(comment.id);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(child: Text(comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : 'А')),
      title: Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
            child: RichText(
              text: TextSpan(
                style: regularStyle,
                children: [
                  if (isReply && comment.parentUserName != null)
                    TextSpan(text: '@${comment.parentUserName} ', style: mentionStyle),
                  TextSpan(text: comment.commentText),
                ],
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30), alignment: Alignment.centerLeft),
            onPressed: () => _startReply(comment),
            child: const Text('Жауап жазу', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (comment.likeCount > 0)
            Text(comment.likeCount.toString(), style: TextStyle(color: isLiked ? Colors.pink : Colors.grey, fontSize: 14)),
          IconButton(
            icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.pink : Colors.grey, size: 20),
            onPressed: () => _handleLikeToggle(comment),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInputField() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,-5))]),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingToCommentId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('Ответ пользователю: ${_replyingToUserName ?? ''}', overflow: TextOverflow.ellipsis)),
                    IconButton(icon: const Icon(Icons.close, size: 18), onPressed: _cancelReply),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    decoration: const InputDecoration(hintText: 'Пікір жазу...'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send_rounded, color: Theme.of(context).primaryColor),
                  onPressed: _postComment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}