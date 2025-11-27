#!/bin/bash

# Clonar Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Build Web
flutter build web --release

# ============================================
# 🔹 COPIAR TU SERVICE WORKER PERSONALIZADO
# ============================================

# Copiar tu propio flutter_service_worker.js
cp web/flutter_service_worker.js build/web/flutter_service_worker.js

# Verificación en logs
echo "🔥 Service Worker personalizado COPIADO a build/web/"
