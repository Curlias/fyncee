# Prompt para Página Web de Fyncee

Crea una landing page moderna y completa para **Fyncee**, una aplicación móvil de finanzas personales. La página debe ser profesional, responsive y seguir exactamente el sistema de diseño de la app.

## 🎨 Sistema de Diseño (CRÍTICO - Usar Exactamente)

### Paleta de Colores

**Tema Oscuro (Principal):**
- Background: `#0A0E27`
- Surface: `#1C1F3A`
- Surface Light: `#2A2D4A`
- Text Primary: `#FFFFFF`
- Text Secondary: `#B0B3C1`
- Text Tertiary: `#6B7280`

**Tema Claro (Alternativo):**
- Background: `#F5F7FA`
- Surface: `#FFFFFF`
- Surface Light: `#F0F2F5`
- Text Primary: `#1A1A1A`
- Text Secondary: `#6B7280`
- Text Tertiary: `#9CA3AF`

**Colores de Acento:**
- Primary (Cyan): `#00D9FF`
- Primary Dark: `#0099CC`
- Income Green: `#00D68F`
- Expense Red: `#FF3B69`
- Warning: `#FFC107`
- Info: `#2196F3`

**Colores de Categorías:**
- Food: `#FFA726`
- Transport: `#42A5F5`
- Tech: `#66BB6A`
- Clothing: `#FFCA28`
- Health: `#EF5350`
- Travel: `#26C6DA`
- Entertainment: `#AB47BC`
- General: `#78909C`

### Tipografía

- **Font Family:** System default sans-serif (Segoe UI, Roboto, SF Pro)
- **Headings:** 
  - H1: 48px, weight 700, letter-spacing 0.3px
  - H2: 36px, weight 700, letter-spacing 0.3px
  - H3: 28px, weight 700, letter-spacing 0.3px
  - H4: 22px, weight 700, letter-spacing 0.3px
- **Body:** 16px, weight 500
- **Small:** 14px, weight 500
- **Caption:** 12px, weight 600

### Estilo Visual

- **Border Radius:** 20px para cards grandes, 16px para botones, 12px para elementos pequeños
- **Shadows:** Sutiles, elevation bajo (Material Design 3)
- **Spacing:** Sistema de 8px (8, 16, 24, 32, 48, 64px)
- **Animations:** Suaves, 300ms cubic-bezier easing

## 📱 Funcionalidades de la App

### Características Principales

1. **Registro de Transacciones**
   - Ingresos y gastos con categorías personalizables
   - Notas opcionales y fecha automática
   - 34 iconos diferentes para categorías
   - Tipos: Ingreso, Gasto, Transferencia

2. **Gestión de Presupuestos**
   - Presupuestos mensuales y anuales por categoría
   - Alertas al 80% y 100% del límite
   - Visualización de progreso con barras
   - Reinicio automático mensual opcional

3. **Sistema de Períodos**
   - Mes actual, mes anterior
   - Últimos 3 meses, últimos 6 meses
   - Año actual, todo el tiempo
   - Períodos personalizados

4. **Configuración Avanzada**
   - Arrastre de saldo del mes anterior
   - Notificaciones de presupuesto
   - Selección de moneda (MXN, USD, EUR)
   - Formato de fecha personalizado
   - Agrupación de transacciones por fecha

5. **Estadísticas y Análisis**
   - Gráficas de gastos por categoría (pie chart)
   - Tendencias de ingresos vs gastos (line chart)
   - Balance general con código de colores
   - Exportación a PDF y CSV

6. **Cloud Sync con Supabase**
   - Sincronización automática en la nube
   - Backup automático
   - Soporte offline con caché local (Hive)
   - PostgreSQL backend

7. **Seguridad**
   - Autenticación biométrica (huella/Face ID)
   - Código PIN opcional
   - Autenticación con Google/Email
   - Row-Level Security en Supabase

8. **Categorías Predefinidas**
   - **Gastos:** Comida, Transporte, Tecnología, Ropa, Salud, Hogar, Educación, Entretenimiento, Viajes, Servicios, Regalos, Mascotas, Belleza, Deportes, Otros
   - **Ingresos:** Salario, Freelance, Inversiones, Regalos, Otros

## 🌐 Estructura de la Página Web

### 1. Hero Section
- **Título impactante:** "Gestiona tus finanzas con claridad"
- **Subtítulo:** "La app de finanzas personales más intuitiva con sincronización en la nube"
- **CTA principal:** "Descargar APK" (botón cyan `#00D9FF`)
- **CTA secundario:** "Ver Demo" (botón outline)
- **Visual:** Mockup de la app mostrando la pantalla principal
- **Background:** Gradiente oscuro `#0A0E27` → `#1C1F3A`

### 2. Características Principales (Features)
Grid de 6 tarjetas con iconos:

1. 📊 **Estadísticas en tiempo real**
   - Visualiza tus gastos e ingresos al instante
   
2. 💰 **Presupuestos inteligentes**
   - Crea límites por categoría y recibe alertas
   
3. 📅 **Períodos flexibles**
   - Analiza por mes, trimestre, año o período personalizado
   
4. ☁️ **Sincronización cloud**
   - Tus datos seguros en Supabase PostgreSQL
   
5. 🔒 **Seguridad biométrica**
   - Protege tu información con huella o Face ID
   
6. 📤 **Exportación PDF/CSV**
   - Descarga tus reportes en múltiples formatos

**Estilo de cada tarjeta:**
- Fondo: `#1C1F3A`
- Border-radius: 20px
- Padding: 32px
- Border: 1px solid rgba(0, 217, 255, 0.1)
- Hover: border cyan + translateY(-4px)

### 3. Screenshots Carousel
Carrusel horizontal con 7 capturas de pantalla:

1. **Pantalla Principal (Home)**
   - Muestra balance, transacciones recientes y selector de período
   
2. **Agregar Transacción**
   - Formulario intuitivo con categorías coloridas
   
3. **Estadísticas y Gráficas**
   - Pie chart de gastos, tendencias mensuales
   
4. **Presupuestos**
   - Lista de presupuestos con barras de progreso
   
5. **Configuración**
   - Opciones de personalización y ajustes
   
6. **Perfil de Usuario**
   - Información de cuenta y avatar
   
7. **Categorías**
   - Gestión de categorías personalizadas

### 4. Funcionalidades Detalladas
Secciones alternas (izquierda-derecha) con imagen/mockup + contenido:

#### Sección 1: Transacciones Inteligentes
- **Imagen:** Mockup agregando transacción
- **Título:** "Registra gastos en segundos"
- **Descripción:** "Añade ingresos y gastos de forma rápida con categorías visuales y notas opcionales"
- **Beneficios:**
  - ✅ 34 iconos de categorías diferentes
  - ✅ Calculadora integrada
  - ✅ Fecha y hora automáticas
  - ✅ Búsqueda y filtros avanzados

#### Sección 2: Presupuestos Visuales
- **Imagen:** Lista de presupuestos con barras
- **Título:** "Controla tus límites de gasto"
- **Descripción:** "Define presupuestos mensuales o anuales y recibe alertas cuando te acerques al límite"
- **Beneficios:**
  - ✅ Alertas al 80% y 100%
  - ✅ Progreso visual con barras
  - ✅ Comparación mes a mes
  - ✅ Reinicio automático mensual

#### Sección 3: Análisis Profundo
- **Imagen:** Gráficas y estadísticas
- **Título:** "Entiende a dónde va tu dinero"
- **Descripción:** "Visualiza tus patrones de gasto con gráficas interactivas y reportes detallados"
- **Beneficios:**
  - ✅ Gráficas de pie y líneas
  - ✅ Análisis por categorías
  - ✅ Tendencias temporales
  - ✅ Exportación a PDF/CSV

#### Sección 4: Cloud Sync Automático
- **Imagen:** Iconos de sincronización
- **Título:** "Tus datos, siempre seguros"
- **Descripción:** "Sincronización automática con Supabase. Accede desde cualquier dispositivo sin perder información"
- **Beneficios:**
  - ✅ Backup automático en la nube
  - ✅ Funciona offline
  - ✅ Sincronización en < 2 segundos
  - ✅ PostgreSQL enterprise-grade

#### Sección 5: Seguridad Primero
- **Imagen:** Huella digital / Face ID
- **Título:** "Protección de nivel bancario"
- **Descripción:** "Autenticación biométrica, código PIN y Row-Level Security en base de datos"
- **Beneficios:**
  - ✅ Huella digital o Face ID
  - ✅ Código PIN personalizado
  - ✅ Autenticación con Google
  - ✅ Encriptación end-to-end

### 5. Tecnologías
Grid de logos/badges con descripción:

1. **Flutter**
   - Framework multiplataforma de Google
   - UI nativa de alto rendimiento
   
2. **Supabase**
   - Backend as a Service
   - PostgreSQL + Auth + Storage
   
3. **PostgreSQL**
   - Base de datos relacional
   - Row-Level Security
   
4. **Hive**
   - Base de datos local NoSQL
   - Caché offline ultrarrápido
   
5. **Material 3**
   - Sistema de diseño de Google
   - Componentes modernos
   
6. **Google Auth**
   - Autenticación segura
   - Single Sign-On

### 6. Estadísticas
Números impactantes en cards:

```
┌─────────────────────────────┐
│      10,000+                │
│  Transacciones Registradas  │
└─────────────────────────────┘

┌─────────────────────────────┐
│       99.9%                 │
│      Uptime                 │
└─────────────────────────────┘

┌─────────────────────────────┐
│        < 2s                 │
│   Sincronización Cloud      │
└─────────────────────────────┘

┌─────────────────────────────┐
│       100%                  │
│  Gratis, Sin Anuncios       │
└─────────────────────────────┘
```

### 7. Pricing (Gratis)
Card destacado centrado:

**"Completamente Gratis"**

✅ Transacciones ilimitadas  
✅ Presupuestos ilimitados  
✅ Sincronización en la nube  
✅ Gráficas y estadísticas  
✅ Exportación PDF/CSV  
✅ Sin anuncios  
✅ Sin límites  
✅ Sin costos ocultos  

**CTA:** "Descargar Ahora" (botón cyan grande)

### 8. FAQ (Accordion)

#### ¿Es completamente gratis?
Sí, Fyncee es 100% gratis, sin anuncios, sin compras dentro de la app y sin límites de uso. Todas las funcionalidades están disponibles desde el primer día.

#### ¿Mis datos están seguros?
Absolutamente. Usamos Supabase con PostgreSQL enterprise-grade, autenticación biométrica, Row-Level Security y encriptación. Tus datos financieros están protegidos al máximo nivel.

#### ¿Funciona sin internet?
Sí, Fyncee funciona perfectamente offline. Todas tus transacciones se guardan localmente con Hive y se sincronizan automáticamente cuando tengas conexión.

#### ¿Puedo exportar mis datos?
Sí, puedes exportar tus transacciones y reportes en formato PDF o CSV en cualquier momento. Tus datos son tuyos.

#### ¿Qué plataformas soporta?
Actualmente Fyncee está disponible para Android (versión 6.0 o superior). Próximamente en iOS y web.

#### ¿Cómo funciona la sincronización?
Fyncee se conecta a Supabase (PostgreSQL) y sincroniza tus datos automáticamente en segundo plano. Si no tienes internet, todo se guarda localmente y se sincroniza después.

#### ¿Puedo crear categorías personalizadas?
Sí, además de las 20+ categorías predefinidas, puedes crear tus propias categorías con iconos y colores personalizados.

#### ¿Hay límite de transacciones?
No, puedes registrar transacciones ilimitadas. Fyncee está diseñado para manejar miles de movimientos sin problemas de rendimiento.

#### ¿Necesito crear una cuenta?
Sí, necesitas una cuenta de Google o email para usar la sincronización en la nube. Esto asegura que tus datos estén respaldados y accesibles desde cualquier dispositivo.

#### ¿Puedo compartir mi cuenta con alguien?
Actualmente cada cuenta es individual. Próximamente agregaremos funcionalidades para familias y cuentas compartidas.

### 9. Download CTA
Sección final impactante:

**Título:** "Comienza a controlar tus finanzas hoy"  
**Subtítulo:** "Descarga gratis y empieza en menos de 2 minutos"

**Botón Principal:** 
```
┌────────────────────────────────────┐
│  📱 Descargar APK (56 MB)          │
│     Android 6.0 o superior         │
└────────────────────────────────────┘
```

**Nota secundaria:** "También disponible próximamente en iOS y Web"

### 10. Footer

```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│  FYNCEE                                                    │
│  Gestiona tus finanzas con claridad                       │
│                                                            │
│  Navegación          Recursos          Legal              │
│  • Inicio            • Documentación   • Privacidad       │
│  • Características   • API             • Términos         │
│  • Descargar         • Soporte         • Cookies          │
│  • Contacto          • GitHub          • Licencias        │
│                                                            │
│  ────────────────────────────────────────────────────────  │
│                                                            │
│  © 2025 Fyncee. Todos los derechos reservados.           │
│  Hecho con ❤️ usando Flutter & Supabase                   │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

**Background:** `#0A0E27`  
**Text Color:** `#B0B3C1`  
**Links Hover:** `#00D9FF`

## 🛠️ Requisitos Técnicos

### Stack Recomendado
- **Framework:** Next.js 14+ con App Router
- **Styling:** Tailwind CSS + CSS Variables para tema
- **Animaciones:** Framer Motion
- **Iconos:** Lucide React (matching Material Icons)
- **Carrusel:** Swiper.js o Embla Carousel
- **Forms:** React Hook Form + Zod
- **Hosting:** Vercel o Netlify

### Responsive Breakpoints
```css
/* Mobile */
@media (max-width: 639px) { }

/* Tablet */
@media (min-width: 640px) and (max-width: 1023px) { }

/* Desktop */
@media (min-width: 1024px) { }

/* Large Desktop */
@media (min-width: 1440px) { }
```

### Performance
- ✅ Lazy loading para imágenes (Next.js Image)
- ✅ Optimización de fuentes (next/font)
- ✅ Code splitting automático
- ✅ Lighthouse score > 90 en todas las métricas
- ✅ First Contentful Paint < 1.5s
- ✅ Time to Interactive < 3s

### SEO
```html
<!-- Meta Tags -->
<title>Fyncee - Gestiona tus finanzas con claridad</title>
<meta name="description" content="App de finanzas personales con sincronización en la nube. Registra gastos, crea presupuestos y visualiza estadísticas. 100% gratis." />
<meta name="keywords" content="finanzas personales, app gastos, presupuesto, control financiero, ahorro" />

<!-- Open Graph -->
<meta property="og:title" content="Fyncee - Gestiona tus finanzas con claridad" />
<meta property="og:description" content="La app de finanzas personales más intuitiva" />
<meta property="og:image" content="/og-image.png" />
<meta property="og:type" content="website" />

<!-- Twitter Card -->
<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:title" content="Fyncee - Gestiona tus finanzas con claridad" />
<meta name="twitter:description" content="La app de finanzas personales más intuitiva" />
<meta name="twitter:image" content="/twitter-image.png" />

<!-- Schema.org -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "MobileApplication",
  "name": "Fyncee",
  "operatingSystem": "Android",
  "applicationCategory": "FinanceApplication",
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "USD"
  }
}
</script>
```

## 📐 Componentes Específicos

### Botón Principal
```css
/* Tailwind Classes */
className="bg-[#00D9FF] text-[#0A0E27] px-8 py-4 rounded-2xl font-bold text-base hover:brightness-110 hover:scale-105 transition-all duration-300"

/* CSS Puro */
.btn-primary {
  background: #00D9FF;
  color: #0A0E27;
  padding: 16px 32px;
  border-radius: 16px;
  font-weight: 700;
  font-size: 16px;
  transition: all 300ms cubic-bezier(0.4, 0, 0.2, 1);
}

.btn-primary:hover {
  filter: brightness(1.1);
  transform: scale(1.02);
}
```

### Card de Característica
```css
/* Tailwind Classes */
className="bg-[#1C1F3A] rounded-[20px] p-8 border border-[#00D9FF]/10 hover:border-[#00D9FF]/30 hover:-translate-y-1 transition-all duration-300"

/* CSS Puro */
.feature-card {
  background: #1C1F3A;
  border-radius: 20px;
  padding: 32px;
  border: 1px solid rgba(0, 217, 255, 0.1);
  transition: all 300ms cubic-bezier(0.4, 0, 0.2, 1);
}

.feature-card:hover {
  border-color: rgba(0, 217, 255, 0.3);
  transform: translateY(-4px);
}
```

### Section Container
```css
/* Tailwind Classes */
className="py-24 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8"

/* CSS Puro */
.section {
  padding-top: 96px;
  padding-bottom: 96px;
  max-width: 1200px;
  margin: 0 auto;
  padding-left: 16px;
  padding-right: 16px;
}

@media (min-width: 640px) {
  .section {
    padding-left: 24px;
    padding-right: 24px;
  }
}

@media (min-width: 1024px) {
  .section {
    padding-left: 32px;
    padding-right: 32px;
  }
}
```

### Gradient Background
```css
/* Tailwind Classes */
className="bg-gradient-to-br from-[#0A0E27] to-[#1C1F3A]"

/* CSS Puro */
.gradient-bg {
  background: linear-gradient(135deg, #0A0E27 0%, #1C1F3A 100%);
}
```

## 🎯 Tono y Mensajes

### Voz de Marca
- ✅ Profesional pero accesible
- ✅ Enfocado en simplicidad y claridad
- ✅ Orientado a resultados
- ✅ Transparente sobre funcionalidades
- ✅ Sin jerga técnica innecesaria

### Mensajes Clave
1. **"Control total de tus finanzas"**
   - Empodera al usuario con información clara

2. **"Sin complicaciones, sin costos ocultos"**
   - Transparencia total, gratis para siempre

3. **"Tus datos, siempre seguros"**
   - Seguridad y privacidad son prioridad

4. **"Sincronización automática en la nube"**
   - Tecnología moderna sin esfuerzo del usuario

5. **"100% gratis, para siempre"**
   - Sin trucos, sin limitaciones

### Ejemplos de Copy

**Hero:**
> "Gestiona tus finanzas con claridad. La app de finanzas personales más intuitiva con sincronización en la nube."

**Features:**
> "Registra gastos en segundos, crea presupuestos inteligentes y visualiza tus patrones de gasto con gráficas hermosas."

**CTA:**
> "Descarga gratis y empieza a tomar control de tus finanzas en menos de 2 minutos."

**Security:**
> "Tus datos financieros protegidos con autenticación biométrica y encriptación de nivel bancario."

## 📦 Entregables

### Páginas
- ✅ Landing page principal (`/`)
- ✅ Página de características (`/features`)
- ✅ Página de descargas (`/download`)
- ✅ Política de privacidad (`/privacy`)
- ✅ Términos de servicio (`/terms`)

### Componentes
- ✅ Navbar responsive con theme toggle
- ✅ Hero section con CTA
- ✅ Features grid (6 cards)
- ✅ Screenshots carousel
- ✅ Feature sections alternas (5 secciones)
- ✅ Tech stack grid
- ✅ Stats counter
- ✅ Pricing card
- ✅ FAQ accordion
- ✅ Download CTA section
- ✅ Footer completo

### Funcionalidades
- ✅ Smooth scroll entre secciones
- ✅ Animaciones de entrada (Framer Motion)
- ✅ Modo oscuro/claro toggle
- ✅ Carrusel de screenshots funcional
- ✅ Accordion FAQ interactivo
- ✅ Botón de descarga con analytics
- ✅ Lazy loading de imágenes
- ✅ SEO optimizado
- ✅ Responsive en todos los breakpoints

### Assets Necesarios
- 📱 Mockups de la app (7 screenshots)
- 🎨 Logo de Fyncee (SVG)
- 🖼️ OG Image para redes sociales
- 🎯 Favicon en múltiples tamaños
- 📊 Iconos de features (Lucide React)
- 💻 Logos de tecnologías (Flutter, Supabase, etc.)

## 🚀 Despliegue

### Vercel (Recomendado)
```bash
# Conectar repositorio GitHub
vercel

# Configurar dominio custom
vercel domains add fyncee.app

# Variables de entorno (si las hay)
NEXT_PUBLIC_ANALYTICS_ID=xxx
```

### Configuración Next.js
```js
// next.config.js
module.exports = {
  images: {
    domains: ['fyncee.app'],
    formats: ['image/avif', 'image/webp'],
  },
  compress: true,
  poweredByHeader: false,
}
```

### Analytics
- Google Analytics 4
- Vercel Analytics
- Download button tracking
- Scroll depth tracking

---

## 📋 Checklist de Implementación

### Fase 1: Setup
- [ ] Crear proyecto Next.js 14
- [ ] Instalar Tailwind CSS
- [ ] Instalar Framer Motion
- [ ] Instalar Lucide React
- [ ] Configurar fuentes (Inter/SF Pro)
- [ ] Setup CSS variables para tema

### Fase 2: Componentes
- [ ] Navbar con theme toggle
- [ ] Hero section
- [ ] Features grid (6 cards)
- [ ] Screenshots carousel
- [ ] Feature sections (5 alternas)
- [ ] Tech stack grid
- [ ] Stats counters
- [ ] Pricing card
- [ ] FAQ accordion
- [ ] Download CTA
- [ ] Footer

### Fase 3: Páginas
- [ ] Landing page (`/`)
- [ ] Features page (`/features`)
- [ ] Download page (`/download`)
- [ ] Privacy page (`/privacy`)
- [ ] Terms page (`/terms`)
- [ ] 404 page

### Fase 4: Optimización
- [ ] Optimizar imágenes (WebP/AVIF)
- [ ] Lazy loading
- [ ] Code splitting
- [ ] Meta tags SEO
- [ ] Open Graph tags
- [ ] Schema.org markup
- [ ] Sitemap.xml
- [ ] robots.txt

### Fase 5: Testing
- [ ] Responsive mobile
- [ ] Responsive tablet
- [ ] Responsive desktop
- [ ] Lighthouse audit (>90)
- [ ] Accessibility audit
- [ ] Cross-browser testing
- [ ] Analytics tracking
- [ ] Download link funcional

### Fase 6: Deploy
- [ ] Conectar a Vercel
- [ ] Configurar dominio
- [ ] Setup analytics
- [ ] Monitor performance
- [ ] Setup error tracking

---

**Nota Final:** La página web debe reflejar exactamente la simplicidad, elegancia y profesionalismo de la app móvil. Usa el tema oscuro como principal (matching `#0A0E27`) y asegúrate de que todos los colores, tipografía y espaciado coincidan EXACTAMENTE con el diseño de la app Flutter.

El objetivo es que el usuario que visite la web sienta la misma experiencia visual que tendrá al usar la app, generando confianza y coherencia en la marca Fyncee.
