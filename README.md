# ShopEase – Smart Product Explorer

A Flutter shopping demo app for the Sankar Group Flutter Developer Internship assignment.

## Features
- Welcome, sign-in and sign-up form validation (demo only; no server authentication)
- Product catalogue with search, category filtering and price sorting
- Product detail view
- Cart quantity controls and subtotal
- Saved/favourite products
- Profile and bottom navigation
- Persistent cart and favourites using SharedPreferences
- Responsive product grid

## Run
1. Install Flutter and Android Studio.
2. Clone this repository.
3. In the project root run:
   ```bash
   flutter pub get
   flutter run
   ```

## Notes
- Product data is structured local sample data.
- Authentication is a UI demonstration; do not enter a real password.
- No payment gateway or backend is connected.
- Cart and saved items persist locally on the device using SharedPreferences.
