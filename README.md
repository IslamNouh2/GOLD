# 🏆 Dahabi Premium Gold Terminal

**Dahabi** is a high-end financial terminal designed for the Algerian market. it provides real-time monitoring of Gold Spot prices and Algerian Black Market ("Square") currency exchange rates across Phone, Tablet, and Android TV.

---

## 🚀 Features

### 1. Real-time Pricing Engine
- **Global Gold Spot**: Fetches real-time 24K gold prices in USD per gram.
- **Algerian Black Market (Square)**: Dynamic tracking of USD/DZD and EUR/DZD rates from unofficial markets.
- **Multi-Purity Support**: Automatic calculation for 24K, 21K, 18K, and 12K gold.
- **Buy/Sell Spread**: Built-in 1.5% market spread (Achat = Vente × 0.985).

### 2. Multi-Language & RTL Support
- Full support for **Arabic (العربية)**, **French (Français)**, and **English**.
- **Dynamic RTL/LTR**: Interface automatically flips layout direction based on the selected language.
- **Language Switcher**: Instant switching via a global language selector.

### 3. Adaptive & Premium UI
- **Cross-Platform**: Optimized layouts for Mobile, Tablet, and Android TV (Adaptive Grid).
- **Glassmorphic Design**: A modern, high-contrast financial interface with rich animations.
- **Landing State**: Professional loading state to prevent flickering and show progress during data sync.

### 4. Resilient Data Layer
- **Hybrid Scraper**: Combines high-precision APIs with robust web fallbacks.
- **Local Persistence**: Uses SQLite to cache rates, ensuring the app remains functional during intermittent connectivity.
- **CORS Optimization**: Integrated proxy support for seamless operation on Flutter Web.

---

## 🛠 Technical Architecture

### Core Components
- **`GoldPricingEngine`**: Centralized logic for all financial calculations (Gram to DZD conversion, Karat factors, and Spreads).
- **`ScraperService`**: Managed background scraping using `http` and `html` parsing.
- **`DataProvider`**: A singleton state manager that broadcasts real-time updates via a `Stream`.
- **`AppLocalizations`**: A custom localization system for dictionary-based translations.

### Technology Stack
- **Framework**: Flutter (Dart)
- **Database**: SQLite (sqflite)
- **Networking**: http + corsproxy.io
- **Themes**: Google Fonts (Inter & JetBrains Mono)

---

## 📊 Gold Pricing Logic

The terminal uses a standardized formula to ensure consistency across all platforms:

1. **Base**: `PriceGram24k_USD` (Fetched from API)
2. **Local Rate**: `USD_DZD_Square` (Fetched from Market Scraper)
3. **Calculation**:
   - `Vente (DZD) = PriceGram24k_USD * USD_DZD_Square * Purity_Factor`
   - `Achat (DZD) = Vente * 0.985` (1.5% Spread)
4. **Factors**:
   - 24K: 1.0
   - 21K: 0.875
   - 18K: 0.75
   - 12K: 0.5

---

## 🚦 Getting Started

### Prerequisites
- Flutter SDK (^3.11.5)
- Android Studio / VS Code

### Installation
1. Clone the repository.
2. Run `flutter pub get`.
3. Launch on your preferred device:
   ```bash
   # For Chrome (Disable Security for Scraping)
   flutter run -d chrome --web-browser-flag "--disable-web-security"
   
   # For Mobile/Tablet
   flutter run
   ```

### Configuration
The terminal is pre-configured to use **api.gold-api.com** (Free) as the primary source for real-time gold pricing. No API key is required for basic usage.

---

## 📝 License
This project is for private use within the Dahabi ecosystem.
