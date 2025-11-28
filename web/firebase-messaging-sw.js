// =====================================================
// 🔹 CACHE DE LA PWA (Offline)
// =====================================================
const CACHE_NAME = 'valetflow-cache-v1';
const urlsToCache = [
  '/',
  '/index.html',
  '/main.dart.js',
  '/manifest.json',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/icons/Icon-maskable-192.png',
  '/icons/Icon-maskable-512.png',
];

// Instalación del Service Worker y cache de recursos
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(urlsToCache))
  );
});

// Activación y limpieza de caches antiguas
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) return caches.delete(key);
        })
      )
    )
  );
});

// Interceptar requests → servir desde cache o fetch
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      return cachedResponse || fetch(event.request);
    })
  );
});

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

// Notificaciones en segundo plano
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message:', payload);

  const notification = payload.notification || {};

  self.registration.showNotification(notification.title, {
    body: notification.body,
    icon: "/icons/Icon-192.png",
  });
});
