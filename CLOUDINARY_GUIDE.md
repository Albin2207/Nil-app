# Cloudinary Video Upload Guide

Since you're using Cloudinary for video hosting (which is a great choice!), here's how to properly upload and get video URLs:

## 📤 How to Upload Videos to Cloudinary

### Method 1: Cloudinary Dashboard (Manual Upload)

1. **Go to Cloudinary Dashboard**
   - Visit: https://cloudinary.com/
   - Log in to your account
   - Go to "Media Library"

2. **Upload Your Video**
   - Click "Upload" button
   - Select your video file
   - Wait for upload to complete

3. **Get the Video URL**
   - Click on the uploaded video
   - Look for the URL in the details panel
   - Copy the full URL
   - Example: `https://res.cloudinary.com/your-cloud-name/video/upload/v1234567890/video_name.mp4`

4. **Get the Thumbnail URL** (Optional)
   - Cloudinary can auto-generate thumbnails
   - Format: Replace `/video/` with `/image/` and add `.jpg`
   - Example: `https://res.cloudinary.com/your-cloud-name/image/upload/v1234567890/video_name.jpg`
   - Or upload a custom thumbnail image separately

### Method 2: Cloudinary Upload API (Programmatic)

If you want to build an admin panel later, you can use the Cloudinary API:

```dart
// Example using http package
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String> uploadToCloudinary(File videoFile) async {
  final url = Uri.parse('https://api.cloudinary.com/v1_1/YOUR_CLOUD_NAME/video/upload');
  
  var request = http.MultipartRequest('POST', url);
  request.fields['upload_preset'] = 'YOUR_UPLOAD_PRESET'; // Create this in Cloudinary settings
  request.files.add(await http.MultipartFile.fromPath('file', videoFile.path));
  
  var response = await request.send();
  var responseData = await response.stream.toBytes();
  var result = json.decode(String.fromCharCodes(responseData));
  
  return result['secure_url']; // This is your video URL
}
```

## 🎬 Get Video Duration

To get the video duration for the Firestore field:

### Option 1: Manual (Using Video Player)
1. Open the video in any video player
2. Check the total duration
3. Convert to seconds
   - Example: 5 minutes 30 seconds = (5 × 60) + 30 = 330 seconds

### Option 2: From Cloudinary
- Cloudinary provides duration in the video details
- Go to Media Library → Click video → See "Duration" field

### Option 3: Programmatically (Flutter)
```dart
import 'package:video_player/video_player.dart';

Future<int> getVideoDuration(String videoUrl) async {
  final controller = VideoPlayerController.network(videoUrl);
  await controller.initialize();
  final duration = controller.value.duration.inSeconds;
  controller.dispose();
  return duration;
}
```

## 🖼️ Create Video Thumbnails

### Option 1: Cloudinary Auto-Generate
Cloudinary automatically creates thumbnails for videos. To get the thumbnail URL:

```
Original video URL:
https://res.cloudinary.com/demo/video/upload/v1234567890/sample.mp4

Thumbnail URL (first frame):
https://res.cloudinary.com/demo/video/upload/v1234567890/sample.jpg

Thumbnail URL (frame at 2 seconds):
https://res.cloudinary.com/demo/video/upload/so_2/sample.jpg

Thumbnail URL (with transformation - 480p):
https://res.cloudinary.com/demo/video/upload/w_480,h_270/v1234567890/sample.jpg
```

### Option 2: Upload Custom Thumbnail
1. Take a screenshot from your video
2. Upload it as an image to Cloudinary
3. Use that image URL as the thumbnail

### Option 3: Use a Placeholder
For testing, you can use placeholder services:
```
https://picsum.photos/480/270?random=1
https://i.pravatar.cc/480
```

## 📋 Complete Upload Checklist

When uploading a video, make sure you have:

- [ ] Video uploaded to Cloudinary
- [ ] Video URL copied
- [ ] Thumbnail URL (auto-generated or custom)
- [ ] Video duration in seconds
- [ ] Video title
- [ ] Video description
- [ ] Channel name
- [ ] Channel avatar URL
- [ ] Initial subscriber count

Then add all these to Firestore!

## 🔒 Cloudinary Security Settings

For production, consider:

1. **Enable Upload Presets**
   - Go to Settings → Upload
   - Create an unsigned upload preset for your app
   - Set folder, transformations, and access controls

2. **Set Resource Type**
   - Make sure videos are set to "video" type
   - Images should be "image" type

3. **Configure Access Control**
   - Public vs Private resources
   - For a YouTube-like app, keep videos public

4. **Enable Transformations**
   - Auto-quality
   - Auto-format
   - Adaptive streaming

## 💡 Pro Tips

1. **Video Format**: Upload in MP4 format for best compatibility
2. **Video Size**: Compress videos before uploading to save bandwidth
3. **Thumbnails**: Always use custom thumbnails for better presentation
4. **Naming**: Use descriptive names for your videos in Cloudinary
5. **Folders**: Organize videos in folders (e.g., "videos/tutorials", "videos/vlogs")

## 📊 Example Complete Video Entry

```json
{
  "title": "How to Build a Flutter App",
  "description": "Learn Flutter development from scratch. In this tutorial, we'll cover...",
  "videoUrl": "https://res.cloudinary.com/mycloud/video/upload/v1730000000/videos/flutter_tutorial.mp4",
  "thumbnailUrl": "https://res.cloudinary.com/mycloud/image/upload/v1730000000/thumbnails/flutter_tutorial_thumb.jpg",
  "channelName": "Flutter Dev Channel",
  "channelAvatar": "https://res.cloudinary.com/mycloud/image/upload/v1730000000/avatars/channel_avatar.jpg",
  "duration": 1245,
  "views": 0,
  "likes": 0,
  "dislikes": 0,
  "subscribers": 50000,
  "timestamp": "2025-10-15T10:30:00Z"
}
```

## 🚀 Automation Ideas (Future)

Create a simple admin panel where you can:
1. Upload video to Cloudinary via API
2. Auto-extract duration
3. Generate thumbnail
4. Fill in details (title, description, etc.)
5. Auto-create Firestore document

This would eliminate manual work!

---

**Happy uploading! 🎥**

