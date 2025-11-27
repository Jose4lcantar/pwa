// =====================================================
// 🔹 CACHE DE LA PWA (Flutter + Firebase Messaging)
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

// Instalar SW
self.addEventListener('install', (event) => {
  console.log('[ServiceWorker] Install');
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[ServiceWorker] Caching app shell');
      return cache.addAll(urlsToCache);
    })
  );
  self.skipWaiting();
});

// Activar SW
self.addEventListener('activate', (event) => {
  console.log('[ServiceWorker] Activate');
  event.waitUntil(
    caches.keys().then((keyList) =>
      Promise.all(
        keyList.map((key) => {
          if (key !== CACHE_NAME) {
            console.log('[ServiceWorker] Removing old cache', key);
            return caches.delete(key);
          }
        })
      )
    )
  );
  self.clients.claim();
});

// Interceptar fetch
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) =>
      response || fetch(event.request)
    )
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
  console.log('[ServiceWorker] Background message:', payload);

  const notification = payload.notification || {};
  const title = notification.title || "Nueva notificación";
  const options = {
    body: notification.body || "",
    icon: "/icons/Icon-192.png",
  };

  self.registration.showNotification(title, options);
});

// =====================================================
// 🔹 (OPCIONAL) Compatibilidad Flutter Web
// =====================================================

// Flutter usa esta variable para saber si el SW ya está listo
self.addEventListener('message', (event) => {
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
  }
});
