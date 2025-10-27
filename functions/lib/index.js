"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onNewComment = exports.onNewSubscriber = exports.onShortUpload = exports.onVideoUpload = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
// Send notification when a new video is uploaded
exports.onVideoUpload = functions.firestore
    .document('videos/{videoId}')
    .onCreate(async (snap, context) => {
    const videoData = snap.data();
    const videoId = context.params.videoId;
    console.log('New video uploaded:', videoId);
    // Get all user tokens
    const tokensSnapshot = await admin.firestore()
        .collection('user_tokens')
        .get();
    if (tokensSnapshot.empty) {
        console.log('No user tokens found');
        return null;
    }
    const tokens = tokensSnapshot.docs.map(doc => doc.data().fcmToken).filter(Boolean);
    if (tokens.length === 0) {
        console.log('No valid FCM tokens found');
        return null;
    }
    const message = {
        notification: {
            title: '🎬 New Video Uploaded!',
            body: `${videoData.title || 'Check out this new video'} by ${videoData.channelName || 'Unknown Channel'}`,
        },
        data: {
            type: 'video_upload',
            videoId: videoId,
            channelId: videoData.uploadedBy || '',
            channelName: videoData.channelName || '',
            videoTitle: videoData.title || '',
        },
        tokens: tokens,
    };
    try {
        const response = await admin.messaging().sendMulticast(message);
        console.log('Successfully sent message:', response);
        console.log(`Sent to ${response.successCount} devices`);
        if (response.failureCount > 0) {
            console.log(`Failed to send to ${response.failureCount} devices`);
            // Clean up invalid tokens
            const invalidTokens = response.responses
                .map((resp, idx) => resp.success ? null : tokens[idx])
                .filter(Boolean);
            if (invalidTokens.length > 0) {
                await cleanupInvalidTokens(invalidTokens);
            }
        }
    }
    catch (error) {
        console.error('Error sending message:', error);
    }
    return null;
});
// Send notification when a new short is uploaded
exports.onShortUpload = functions.firestore
    .document('shorts/{shortId}')
    .onCreate(async (snap, context) => {
    const shortData = snap.data();
    const shortId = context.params.shortId;
    console.log('New short uploaded:', shortId);
    // Get all user tokens
    const tokensSnapshot = await admin.firestore()
        .collection('user_tokens')
        .get();
    if (tokensSnapshot.empty) {
        console.log('No user tokens found');
        return null;
    }
    const tokens = tokensSnapshot.docs.map(doc => doc.data().fcmToken).filter(Boolean);
    if (tokens.length === 0) {
        console.log('No valid FCM tokens found');
        return null;
    }
    const message = {
        notification: {
            title: '⚡ New Short Available!',
            body: `${shortData.title || 'Check out this new short'} by ${shortData.channelName || 'Unknown Channel'}`,
        },
        data: {
            type: 'short_upload',
            shortId: shortId,
            channelId: shortData.uploadedBy || '',
            channelName: shortData.channelName || '',
            shortTitle: shortData.title || '',
        },
        tokens: tokens,
    };
    try {
        const response = await admin.messaging().sendMulticast(message);
        console.log('Successfully sent short notification:', response);
        console.log(`Sent to ${response.successCount} devices`);
        if (response.failureCount > 0) {
            console.log(`Failed to send to ${response.failureCount} devices`);
            // Clean up invalid tokens
            const invalidTokens = response.responses
                .map((resp, idx) => resp.success ? null : tokens[idx])
                .filter(Boolean);
            if (invalidTokens.length > 0) {
                await cleanupInvalidTokens(invalidTokens);
            }
        }
    }
    catch (error) {
        console.error('Error sending short notification:', error);
    }
    return null;
});
// Helper function to clean up invalid FCM tokens
async function cleanupInvalidTokens(invalidTokens) {
    console.log('Cleaning up invalid tokens:', invalidTokens.length);
    const batch = admin.firestore().batch();
    for (const token of invalidTokens) {
        const tokenQuery = await admin.firestore()
            .collection('user_tokens')
            .where('fcmToken', '==', token)
            .get();
        tokenQuery.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
    }
    await batch.commit();
    console.log('Cleaned up invalid tokens');
}
// Send notification when user gets new subscribers
exports.onNewSubscriber = functions.firestore
    .document('users/{userId}/subscribers/{subscriberId}')
    .onCreate(async (snap, context) => {
    const subscriberData = snap.data();
    const userId = context.params.userId;
    const subscriberId = context.params.subscriberId;
    console.log('New subscriber for user:', userId);
    // Get the channel owner's FCM token
    const userDoc = await admin.firestore()
        .collection('users')
        .doc(userId)
        .get();
    if (!userDoc.exists) {
        console.log('User not found');
        return null;
    }
    const userData = userDoc.data();
    const fcmToken = userData === null || userData === void 0 ? void 0 : userData.fcmToken;
    if (!fcmToken) {
        console.log('No FCM token for user');
        return null;
    }
    const message = {
        notification: {
            title: '🎉 New Subscriber!',
            body: `${subscriberData.subscriberName || 'Someone'} subscribed to your channel`,
        },
        data: {
            type: 'new_subscriber',
            userId: userId,
            subscriberId: subscriberId,
            subscriberName: subscriberData.subscriberName || '',
        },
        token: fcmToken,
    };
    try {
        const response = await admin.messaging().send(message);
        console.log('Successfully sent subscriber notification:', response);
    }
    catch (error) {
        console.error('Error sending subscriber notification:', error);
    }
    return null;
});
// Send notification when video gets new comments
exports.onNewComment = functions.firestore
    .document('videos/{videoId}/comments/{commentId}')
    .onCreate(async (snap, context) => {
    const commentData = snap.data();
    const videoId = context.params.videoId;
    const commentId = context.params.commentId;
    console.log('New comment on video:', videoId);
    // Get video data to find the channel owner
    const videoDoc = await admin.firestore()
        .collection('videos')
        .doc(videoId)
        .get();
    if (!videoDoc.exists) {
        console.log('Video not found');
        return null;
    }
    const videoData = videoDoc.data();
    const channelOwnerId = videoData === null || videoData === void 0 ? void 0 : videoData.uploadedBy;
    if (!channelOwnerId) {
        console.log('No channel owner found');
        return null;
    }
    // Get the channel owner's FCM token
    const userDoc = await admin.firestore()
        .collection('users')
        .doc(channelOwnerId)
        .get();
    if (!userDoc.exists) {
        console.log('Channel owner not found');
        return null;
    }
    const userData = userDoc.data();
    const fcmToken = userData === null || userData === void 0 ? void 0 : userData.fcmToken;
    if (!fcmToken) {
        console.log('No FCM token for channel owner');
        return null;
    }
    const message = {
        notification: {
            title: '💬 New Comment!',
            body: `${commentData.commenterName || 'Someone'} commented on your video: ${videoData.title || 'Untitled'}`,
        },
        data: {
            type: 'new_comment',
            videoId: videoId,
            commentId: commentId,
            commenterName: commentData.commenterName || '',
            videoTitle: videoData.title || '',
        },
        token: fcmToken,
    };
    try {
        const response = await admin.messaging().send(message);
        console.log('Successfully sent comment notification:', response);
    }
    catch (error) {
        console.error('Error sending comment notification:', error);
    }
    return null;
});
//# sourceMappingURL=index.js.map