class Short {
  final String id;
  final String title;
  final String channel;
  final String channelHandle;
  final String channelAvatar;
  final String views;
  final String thumbnail;
  int likes;
  int comments;
  bool isLiked;
  bool isDisliked;
  bool isSubscribed;

  Short({
    required this.id,
    required this.title,
    required this.channel,
    required this.channelHandle,
    required this.channelAvatar,
    required this.views,
    required this.thumbnail,
    required this.likes,
    required this.comments,
    this.isLiked = false,
    this.isDisliked = false,
    this.isSubscribed = false,
  });
}
