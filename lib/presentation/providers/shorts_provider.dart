// import 'package:flutter/material.dart';
// import 'package:nil_app/data/models/shorts_model.dart';

// class ShortProvider extends ChangeNotifier {
//   final List<Short> _shorts = [
//     Short(
//       id: '1',
//       title: 'Who air dropped me this😅',
//       channel: 'Comedy Central',
//       channelHandle: '@comedycentral',
//       channelAvatar: '😂',
//       views: '2.5M',
//       thumbnail: 'https://picsum.photos/seed/short1/300/533',
//       likes: 125000,
//       comments: 1520,
//     ),
//     Short(
//       id: '2',
//       title: 'Try Not to Laugh Challenge 873 🤣 #funny',
//       channel: 'Laugh Factory',
//       channelHandle: '@laughfactory',
//       channelAvatar: '🎭',
//       views: '1.8M',
//       thumbnail: 'https://picsum.photos/seed/short2/300/533',
//       likes: 98000,
//       comments: 2340,
//     ),
//     Short(
//       id: '3',
//       title: 'KSI\'s New Trim 🔥',
//       channel: 'Sports Clips',
//       channelHandle: '@sportsclips',
//       channelAvatar: '⚽',
//       views: '3.2M',
//       thumbnail: 'https://picsum.photos/seed/short3/300/533',
//       likes: 210000,
//       comments: 3890,
//     ),
//     Short(
//       id: '4',
//       title: 'Types of Pirivukar | Karikku',
//       channel: 'Karikku',
//       channelHandle: '@karikku',
//       channelAvatar: '🎬',
//       views: '11M',
//       thumbnail: 'https://picsum.photos/seed/short4/300/533',
//       likes: 450000,
//       comments: 5670,
//     ),
//     Short(
//       id: '5',
//       title: 'The Storm-Chasing Machine That Laughs at Danger',
//       channel: 'OTOMAN2864',
//       channelHandle: '@OTOMAN2864',
//       channelAvatar: '🌪️',
//       views: '5.7M',
//       thumbnail: 'https://picsum.photos/seed/short5/300/533',
//       likes: 320000,
//       comments: 1379,
//     ),
//     Short(
//       id: '6',
//       title: 'When the beat drops perfectly 🎵',
//       channel: 'Music Vibes',
//       channelHandle: '@musicvibes',
//       channelAvatar: '🎵',
//       views: '4.3M',
//       thumbnail: 'https://picsum.photos/seed/short6/300/533',
//       likes: 280000,
//       comments: 2100,
//     ),
//     Short(
//       id: '7',
//       title: 'POV: You just discovered this hack 🤯',
//       channel: 'Life Hacks Daily',
//       channelHandle: '@lifehacksdaily',
//       channelAvatar: '💡',
//       views: '6.1M',
//       thumbnail: 'https://picsum.photos/seed/short7/300/533',
//       likes: 385000,
//       comments: 2890,
//     ),
//     Short(
//       id: '8',
//       title: 'This dance move is INSANE 🕺',
//       channel: 'Dance Fever',
//       channelHandle: '@dancefever',
//       channelAvatar: '💃',
//       views: '8.9M',
//       thumbnail: 'https://picsum.photos/seed/short8/300/533',
//       likes: 520000,
//       comments: 4320,
//     ),
//   ];

//   List<Short> get shorts => _shorts;

//   void toggleLike(String id) {
//     final short = _shorts.firstWhere((s) => s.id == id);
//     if (short.isLiked) {
//       short.isLiked = false;
//       short.likes--;
//     } else {
//       short.isLiked = true;
//       short.likes++;
//       if (short.isDisliked) {
//         short.isDisliked = false;
//       }
//     }
//     notifyListeners();
//   }

//   void toggleDislike(String id) {
//     final short = _shorts.firstWhere((s) => s.id == id);
//     if (short.isDisliked) {
//       short.isDisliked = false;
//     } else {
//       short.isDisliked = true;
//       if (short.isLiked) {
//         short.isLiked = false;
//         short.likes--;
//       }
//     }
//     notifyListeners();
//   }

//   void toggleSubscribe(String id) {
//     final short = _shorts.firstWhere((s) => s.id == id);
//     short.isSubscribed = !short.isSubscribed;
//     notifyListeners();
//   }
// }
