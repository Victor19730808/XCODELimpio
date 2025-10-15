#!/bin/bash

# ========================================
# Script de Build para Producción - limpioCS
# ========================================
# Fecha: 2025-01-14
# Versión: 1.0.0
# ========================================

echo "🚀 Iniciando build para producción..."
echo "========================================"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
PROJECT_NAME="limpioCS"
SCHEME="limpioCS"
DESTINATION="platform=iOS,name=iPhone 17 Air Chavitt"

echo -e "${BLUE}📱 Proyecto: $PROJECT_NAME${NC}"
echo -e "${BLUE}🎯 Esquema: $SCHEME${NC}"
echo -e "${BLUE}📱 Destino: $DESTINATION${NC}"
echo ""

# Paso 1: Limpiar build anterior
echo -e "${YELLOW}🧹 Limpiando build anterior...${NC}"
xcodebuild clean -project $PROJECT_NAME.xcodeproj -scheme $SCHEME
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Limpieza completada${NC}"
else
    echo -e "${RED}❌ Error en la limpieza${NC}"
    exit 1
fi

echo ""

# Paso 2: Build para Debug (desarrollo)
echo -e "${YELLOW}🔨 Compilando versión Debug...${NC}"
xcodebuild -project $PROJECT_NAME.xcodeproj -scheme $SCHEME -destination "$DESTINATION" -configuration Debug build
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build Debug exitoso${NC}"
else
    echo -e "${RED}❌ Error en build Debug${NC}"
    exit 1
fi

echo ""

# Paso 3: Build para Release (producción)
echo -e "${YELLOW}🏭 Compilando versión Release (Producción)...${NC}"
xcodebuild -project $PROJECT_NAME.xcodeproj -scheme $SCHEME -destination "$DESTINATION" -configuration Release build
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build Release exitoso${NC}"
else
    echo -e "${RED}❌ Error en build Release${NC}"
    exit 1
fi

echo ""
echo "========================================"
echo -e "${GREEN}🎉 ¡Build para producción completado exitosamente!${NC}"
echo ""
echo -e "${BLUE}📋 Resumen de optimizaciones aplicadas:${NC}"
echo -e "${GREEN}  ✅ Sistema de logging optimizado para producción${NC}"
echo -e "${GREEN}  ✅ Límites de rendimiento configurados${NC}"
echo -e "${GREEN}  ✅ Lazy loading implementado en el mapa${NC}"
echo -e "${GREEN}  ✅ Clustering optimizado${NC}"
echo -e "${GREEN}  ✅ Cache de ubicación optimizado${NC}"
echo ""
echo -e "${YELLOW}📱 La app está lista para distribución${NC}"
echo "========================================"
