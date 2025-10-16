# Firebase Firestore Data Structure

This document explains the required data structure for videos in your Firestore database.

## Collection: `videos`

Each video document should have the following fields:

```json
{
  "title": "Your Video Title",
  "description": "Your video description here...",
  "videoUrl": "https://res.cloudinary.com/your-cloudinary-path/video.mp4",
  "thumbnailUrl": "https://res.cloudinary.com/your-cloudinary-path/thumbnail.jpg",
  "channelName": "Channel Name",
  "channelAvatar": "https://i.pravatar.cc/150?img=2",
  "duration": 300,
  "views": 0,
  "likes": 0,
  "dislikes": 0,
  "subscribers": 12500,
  "timestamp": [Firestore Timestamp - use serverTimestamp()]
}
```

### Field Descriptions:

- **title** (String): The title of the video
- **description** (String): Detailed description of the video
- **videoUrl** (String): Direct URL to the video file (from Cloudinary or any CDN)
- **thumbnailUrl** (String): URL to the video thumbnail image
- **channelName** (String): Name of the channel/creator
- **channelAvatar** (String): URL to the channel avatar/profile picture
- **duration** (Number): Video duration in seconds (e.g., 300 for 5 minutes)
- **views** (Number): Number of views (starts at 0, auto-incremented)
- **likes** (Number): Number of likes (starts at 0)
- **dislikes** (Number): Number of dislikes (starts at 0)
- **subscribers** (Number): Number of channel subscribers
- **timestamp** (Timestamp): When the video was uploaded

## Subcollection: `videos/{videoId}/comments`

Comments are stored as a subcollection under each video. Each comment should have:

```json
{
  "text": "This is a comment",
  "username": "User Name",
  "userAvatar": "https://i.pravatar.cc/150?img=1",
  "timestamp": [Firestore Timestamp],
  "likes": 0
}
```

## How to Add a Video Manually (Firebase Console):

1. Go to Firebase Console → Firestore Database
2. Click on the `videos` collection (create it if it doesn't exist)
3. Click "Add Document"
4. Auto-generate an ID or provide a custom one
5. Add all the fields listed above with their respective values
6. For timestamp, use the server timestamp (click the clock icon)
7. Make sure `duration` is a **Number** type, not String
8. Make sure `views`, `likes`, `dislikes`, and `subscribers` are **Number** types

## Example Video Document:

```
Document ID: video_001

Fields:
- title: "Amazing Flutter Tutorial"
- description: "Learn Flutter in 2025 with this comprehensive guide"
- videoUrl: "https://res.cloudinary.com/demo/video/upload/v1234567890/sample.mp4"
- thumbnailUrl: "https://res.cloudinary.com/demo/image/upload/v1234567890/thumbnail.jpg"
- channelName: "Flutter Mastery"
- channelAvatar: "https://i.pravatar.cc/150?img=5"
- duration: 720 (12 minutes)
- views: 0
- likes: 0
- dislikes: 0
- subscribers: 50000
- timestamp: [Current Server Timestamp]
```

## Notes:

- The comments subcollection will be created automatically when users post comments
- Views are automatically incremented when someone opens a video
- Likes and dislikes are updated when users interact with the buttons
- You don't need Firebase Storage - Cloudinary URLs work perfectly fine!
- Make sure your Cloudinary videos are set to public access

## Quick Test URLs

For testing purposes, you can use these free public video URLs:

```
Video 1: https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4
Video 2: https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4
Video 3: https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4
```

These are hosted by Google and always available!

