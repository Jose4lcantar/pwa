// =====================================================
// 🔹 FIREBASE MESSAGING (Background Push Notifications)
// =====================================================

importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCTSWg1isO7d_zgSKeMTwIjB8NSp_gBU0o",
  appId: "1:835667889247:web:6d86da70f314e33dea9fea",
  messagingSenderId: "835667889247",
  projectId: "valetflowqr-40544",
  authDomain: "valetflowqr-40544.firebaseapp.com",
  storageBucket: "valetflowqr-40544.firebasestorage.app"
});

const messaging = firebase.messaging();

// Notificaciones en segundo plano (app cerrada o PWA cerrada)
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message:', payload);

  const notification = payload.notification || {};

  self.registration.showNotification(notification.title, {
    body: notification.body,
    icon: "/icons/Icon-192.png",
  });
});

