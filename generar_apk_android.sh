#!/bin/bash

# =====================================================
# SCRIPT PARA GENERAR APK DE FYNCEE ANDROID
# =====================================================

echo "🚀 Iniciando proceso de generación de APK..."
echo ""

# 1. Limpiar builds anteriores
echo "🧹 Limpiando builds anteriores..."
flutter clean
if [ $? -ne 0 ]; then
    echo "❌ Error al limpiar el proyecto"
    exit 1
fi
echo "✅ Limpieza completada"
echo ""

# 2. Obtener dependencias
echo "📦 Obteniendo dependencias..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "❌ Error al obtener dependencias"
    exit 1
fi
echo "✅ Dependencias obtenidas"
echo ""

# 3. Verificar que no haya errores de análisis
echo "🔍 Analizando código..."
flutter analyze
if [ $? -ne 0 ]; then
    echo "⚠️  Hay warnings en el código, pero continuando..."
fi
echo ""

# 4. Construir APK en modo release
echo "🔨 Construyendo APK en modo release..."
echo "⏱️  Esto puede tomar varios minutos..."
flutter build apk --release
if [ $? -ne 0 ]; then
    echo "❌ Error al construir el APK"
    exit 1
fi
echo "✅ APK construido exitosamente"
echo ""

# 5. Mostrar información del APK generado
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
    echo "✅ APK generado en: $APK_PATH"
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo "📦 Tamaño del APK: $APK_SIZE"
    echo ""
    echo "📱 Para instalar en tu dispositivo Android:"
    echo "   1. Conecta tu dispositivo por USB"
    echo "   2. Habilita 'Instalación de fuentes desconocidas'"
    echo "   3. Ejecuta: adb install $APK_PATH"
    echo "   O copia el archivo a tu dispositivo y ábrelo"
    echo ""
else
    echo "❌ No se encontró el APK generado"
    exit 1
fi

echo "🎉 ¡Proceso completado!"
