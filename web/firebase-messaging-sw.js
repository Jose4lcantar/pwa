// IMPORTS NECESARIOS PARA FCM
importScripts('https://www.gstatic.com/firebasejs/9.6.11/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.11/firebase-messaging-compat.js');

// CONFIG SACADO DE firebase_options.dart → web
firebase.initializeApp({
  apiKey: "AIzaSyCTSWg1isO7d_zgSKeMTwIjB8NSp_gBU0o",
  appId: "1:835667889247:web:6d86da70f314e33dea9fea",
  messagingSenderId: "835667889247",
  projectId: "valetflowqr-40544",
  authDomain: "valetflowqr-40544.firebaseapp.com",
  storageBucket: "valetflowqr-40544.firebasestorage.app"
});

// ACTIVAR MENSAJERÍA
const messaging = firebase.messaging();

// HANDLER PARA NOTIFICACIONES EN SEGUNDO PLANO
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Mensaje en background recibido:', payload);

  const notificationTitle = payload.notification?.title || "Notificación";
  const notificationOptions = {
    body: payload.notification?.body || "",
    icon: "/icons/Icon-192.png",
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
