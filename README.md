# ShopEase – Smart Product Explorer

Flutter Developer Internship assignment project for Sankar Group.

## Features
- Sign-in / sign-up demo screen with email and password validation
- Guest entry
- Product catalogue with search, category filters and price sorting
- Product details
- Add/remove cart quantities and subtotal
- Saved/favourite products
- Profile and bottom navigation
- Local persistence for cart and saved products using SharedPreferences
- Responsive two-column product grid

## Setup on Windows
1. Install Flutter and Android Studio, then clone this repository.
2. Open PowerShell in the repository folder.
3. Generate the Android and web platform folders:
   ```powershell
   flutter create --platforms=android,web .
   ```
4. Install dependencies and run:
   ```powershell
   flutter pub get
   flutter run
   ```

## Important notes
- Product catalogue uses structured local sample data.
- Sign-in/sign-up is front-end validation only. No real account is created and no real password should be used.
- Cart and saved products are stored locally on the device using SharedPreferences.
- Checkout is a preview only. No payment gateway or backend is connected.
- Run `flutter analyze` and test on a physical device before final submission.
