# Orion App Blueprint

## 1. Overview

**Project:** Orion - Financial Command Center

**Purpose:** A mobile-first Flutter application designed to provide users with a clear and intuitive dashboard for their finances. The app will feature a clean, modern, light interface to make financial tracking feel simple and approachable.

**Tone:** Professional, data-driven, polished, and engaging.

## 2. Style & Design System (Light Theme)

*   **Theme:** A clean, light theme is the primary and only theme.
*   **Primary Color Palette:**
    *   **Background:** `#FFFFFF` (White).
    *   **Primary Text:** `#000000` (Black).
    *   **Secondary Text:** `Colors.grey`.
    *   **Accent/Interactive:** `#1976D2` (A specific, professional blue).
    *   **Positive Change/Credit:** `#00D09C` (A vibrant green).
    *   **Negative Change/Debit:** A standard red.
*   **Typography (`google_fonts`):
    *   **Headlines/Titles:** `Roboto` (Bold).
    *   **Body/Subtitles:** `Open Sans`.
*   **Layout:** Spacious layouts with consistent padding (around 20.0 logical pixels).

## 3. Core Features & Screens

### Screen 3: Stock Detail (Final Professional Design)

*   **Objective:** Create a rich, professional, and clean UI inspired by top-tier financial applications.
*   **Layout Strategy:** A `SingleChildScrollView` containing a single `Column` for a streamlined, non-tabbed view.
*   **Component Structure:**
    1.  **AppBar:** Minimalist, with a transparent background and a simple back arrow.
    2.  **Price Header:** Displays the asset name, the current price, the daily percentage change, and a star icon.
    3.  **Chart View:** A placeholder for the price chart, followed by a horizontal time-range selector.
    4.  **Wallet Card:** A card showing the user's holdings.
    5.  **Trade Button:** A large, prominent, solid blue button.
    6.  **About Section:** A simple title indicating more information is available.
    7.  **Recent Transactions:** A new list widget showing recent buy/sell activity, inspired by professional banking UI kits.

## 4. Current Task: Add a "Recent Transactions" Widget

1.  **Update Blueprint:** Document the addition of the new transaction history feature. **(Completed)**
2.  **Create New V5 Components:** Build the `TransactionHistory` and `TransactionListItem` widgets.
3.  **Integrate into `stock_detail_screen.dart`:** Add the new widget to the main layout.
4.  **Verification:** Run the app to showcase the enhanced, more complete design.
