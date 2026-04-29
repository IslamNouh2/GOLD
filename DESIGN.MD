---
name: Dahabi
colors:
  surface: '#121222'
  surface-dim: '#121222'
  surface-bright: '#38374a'
  surface-container-lowest: '#0c0c1d'
  surface-container-low: '#1a1a2b'
  surface-container: '#1e1e2f'
  surface-container-high: '#29283a'
  surface-container-highest: '#333345'
  on-surface: '#e3e0f8'
  on-surface-variant: '#d0c5af'
  inverse-surface: '#e3e0f8'
  inverse-on-surface: '#2f2f40'
  outline: '#99907c'
  outline-variant: '#4d4635'
  surface-tint: '#e9c349'
  primary: '#f2ca50'
  on-primary: '#3c2f00'
  primary-container: '#d4af37'
  on-primary-container: '#554300'
  inverse-primary: '#735c00'
  secondary: '#fff9ef'
  on-secondary: '#3a3000'
  secondary-container: '#ffdb3c'
  on-secondary-container: '#725f00'
  tertiary: '#cecbe7'
  on-tertiary: '#2f2e43'
  tertiary-container: '#b2b0cb'
  on-tertiary-container: '#434359'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffe088'
  primary-fixed-dim: '#e9c349'
  on-primary-fixed: '#241a00'
  on-primary-fixed-variant: '#574500'
  secondary-fixed: '#ffe16d'
  secondary-fixed-dim: '#e9c400'
  on-secondary-fixed: '#221b00'
  on-secondary-fixed-variant: '#544600'
  tertiary-fixed: '#e2e0fc'
  tertiary-fixed-dim: '#c6c4df'
  on-tertiary-fixed: '#1a1a2e'
  on-tertiary-fixed-variant: '#45455b'
  background: '#121222'
  on-background: '#e3e0f8'
  surface-variant: '#333345'
typography:
  display-gold:
    fontFamily: Work Sans
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-ticker:
    fontFamily: Work Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: 0.05em
  body-arabic:
    fontFamily: System Arabic
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  data-mono:
    fontFamily: Work Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.02em
  label-caps:
    fontFamily: Work Sans
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.1em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  unit: 4px
  gutter: 12px
  margin-edge: 20px
  row-height-dense: 40px
  row-height-standard: 56px
---

## Brand & Style

This design system is built for the high-net-worth individual who demands the precision of a financial terminal and the aesthetic of a luxury timepiece. The brand personality is authoritative, exclusive, and hyper-accurate. 

The visual style is a fusion of **Bloomberg Terminal density** and **Modern Luxury**. It prioritizes information density and legibility while using light and texture to signify value. Subtle gold shimmer gradients and high-contrast gold-on-navy accents create an interface that feels less like an app and more like a high-end physical asset. 

Key stylistic principles:
- **Precision First:** Data is never obscured by decoration.
- **Lustrous Accents:** Gold is used as a functional tool for highlighting and action, never as a background wash.
- **Atmospheric Depth:** The UI utilizes a "deep space" dark mode to make the gold elements appear to emit light.

## Colors

The palette is anchored in a dual-tone deep navy system to provide more depth than standard black. The primary **Classic Gold (#D4AF37)** is reserved for primary branding, icons, and significant data points. The **Highlight Gold (#FFD700)** is used exclusively for interactive states and "live" price fluctuations to draw immediate eye contact.

For data visualization and price tracking:
- **Base Background:** #0A0A1A (Deep Navy) for the primary canvas.
- **Alternating Rows:** #1A1A2E and #16213E are used to maintain horizontal scanning speed in dense lists, mimicking a professional trading desk environment.
- **Status Colors:** High-saturation greens and reds are used for price delta indicators, optimized for maximum contrast against the navy background.

## Typography

The typographic system relies on **Work Sans** for its professional, industrial clarity. While the UI supports RTL Arabic text, all numerical data—the core of the app—should utilize tabular lining figures to ensure that decimals and digits align perfectly in vertical columns, facilitating instant price comparison.

**Arabic Requirements:**
The Arabic typeface must be a clean, modern Naskh-style sans-serif. It should maintain a similar x-height to Work Sans to ensure visual harmony in bilingual strings.

**Information Hierarchy:**
- **Numbers:** Bold, monospaced-style appearance for ticker prices and weights.
- **Labels:** Small-caps or heavy-weight labels for metadata to distinguish from primary values.
- **Gold Highlights:** Critical headers should occasionally utilize a subtle linear gradient (Top-Bottom: #FFD700 to #D4AF37) to denote premium information levels.

## Layout & Composition (Reference Image)

The Dahabi Terminal UI is structured into four primary vertical sections designed for high-density information display:

1.  **Global App Bar:**
    - **Left:** Circular refresh button (#F2CA50) + "Dernière Mise à Jour" timestamp (Work Sans, White/Gold).
    - **Center:** Bilingual Title: "PRIX DE L'OR | أسعار الذهب" in bold gold.
    - **Right:** Hamburger menu icon.

2.  **Market Ticker (Strip):**
    - High-contrast marquee strip directly below the app bar.
    - Format: `CHANGE%  VALUE  :SYMBOL`.
    - Semantic coloring for percentages (Green for up, Red for down).

3.  **Hero Display:**
    - **Background:** High-resolution image of brushed gold bars with a dark vignette.
    - **Overlay:** "Live Market" pill badge (Gold border, #F2CA50 text).
    - **Typography:** "Dahabi Terminal" (Work Sans Bold, White) + Arabic tagline in clean Naskh.
    - **Styling:** Glassmorphic container with 0.25rem radius.

4.  **The Ticker Table (Core Data):**
    - **Header Row:** 4 columns: `النوع / Type`, `سعر الشراء (Prix Achat)`, `سعر البيع (Prix Vente)`, `الفرق (% Taux)`.
    - **Row Density:** Alternating navy backgrounds (#1A1A2B / #121222).
    - **Content:**
        - Gold Purity/Weight (e.g., 24K Gold, Lingot 10g).
        - Prices in AED (or local currency) with tabular lining figures.
        - Percentage change in high-saturation green.

## Colors & Texture (Updated)

- **Primary Background:** #0A0A1A (Deep Navy).
- **Secondary Surfaces:** #1A1A2E.
- **Accents:** #F2CA50 (Vibrant Gold) and #D4AF37 (Burnished Gold).
- **Glassmorphism:** 70% opacity with 12px blur for the Hero overlay and Header.
- **Borders:** 1px hairlines (#F2CA50 at 20% opacity).

## Components

### Hero Section
- Must utilize a high-quality asset from `generate_image`.
- Content is right-aligned for bilingual balance.

### Data Table
- Columns are perfectly aligned.
- Values utilize `data-mono` (tabular figures).
- Row height is dense (40px-48px).