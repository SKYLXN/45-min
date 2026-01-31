# 45min - Project to learn flutter.

## Overview
 Smart fitness coaching app with automated body analytics, adaptive workout planning, and nutrition integration.

 This repository is a personal learning project created for fun to explore building a Flutter app for iOS and Android and integrating external services. The code is released under the MIT License (see LICENSE).


## Project Structure
```
lib/
├── core/
│   ├── constants/      # App-wide constants (colors, strings, etc.)
│   ├── theme/          # Theme configuration
│   ├── router/         # Navigation setup
│   ├── utils/          # Helper utilities
│   └── widgets/        # Reusable widgets
│
├── features/
│   ├── onboarding/     # User onboarding flow
│   ├── home/           # Home dashboard
│   ├── body_metrics/   # Body composition tracking
│   ├── smart_planner/  # Workout program generation
│   ├── workout_mode/   # Active workout tracking
│   ├── exercise_database/  # Exercise library
│   └── nutrition/      # Meal suggestions & tracking
│
└── main.dart           # App entry point
```

## Features

### 1. Body Metrics
Track and monitor your body composition and key fitness metrics.

- 📊 Manual body metrics input and tracking
- 📈 Progress charts and trend analysis
- 🎯 Body composition goals tracking

### 2. Smart Planner
- Automated workout program generation
- Progressive overload algorithm
- A/B split scheduling
- Equipment-based exercise filtering

### 3. Workout Mode
- Real-time workout tracking
- Auto rest timer
- Quick rep/weight logging
- Previous performance comparison
- Exercise swap functionality

### 4. Exercise Database
- Filterable by muscle group
- Filterable by equipment
- Video/GIF demonstrations
- Tempo indicators

### 5. Nutrition Module
- BMR-based calorie calculation
- API-powered meal suggestions
- Post-workout vs Rest day recommendations
- Macro tracking

## Setup Instructions

### Prerequisites
- Flutter SDK (>=3.2.0)
- Dart SDK
- Android Studio / Xcode for mobile development

### Installation

1. **Install Flutter**
   ```bash
   # macOS
   brew install flutter
   
   # Or download from https://docs.flutter.dev/get-started/install
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run Code Generation** (for models and API clients)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the App**
   ```bash
   # For iOS Simulator
   flutter run -d ios
   
   # For Android Emulator
   flutter run -d android
   
   # For Chrome (Web)
   flutter run -d chrome
   ```

## Dependencies

### Core
- `flutter_riverpod`: State management
- `go_router`: Navigation
- `shared_preferences`: Local storage
- `sqflite`: Local database

### UI
- `fl_chart`: Charts and graphs
- `shimmer`: Loading animations
- `lottie`: Complex animations
- `cached_network_image`: Image caching

### API & Networking
- `dio`: HTTP client
- `retrofit`: Type-safe API client
- `json_annotation`: JSON serialization

## API Integration

### Nutrition APIs (Choose one)
1. **Spoonacular** (Recommended)
   - Sign up: https://spoonacular.com/food-api
   - Add API key to `lib/core/constants/app_constants.dart`

2. **Edamam**
   - Sign up: https://www.edamam.com/
   - Add API key and App ID to constants

## Development Guidelines

### Code Style
- Follow Flutter style guide
- Use meaningful variable names
- Add documentation comments for public APIs
- Keep widgets small and focused

### State Management
- Use Riverpod providers for business logic
- Keep UI widgets stateless when possible
- Avoid prop drilling - use providers

### File Naming
- Screen: `*_screen.dart`
- Widget: `*_widget.dart`
- Model: `*_model.dart`
- Provider: `*_provider.dart`
- Repository: `*_repository.dart`

## Testing
```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test

# Run with coverage
flutter test --coverage
```

## Build for Production

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ipa --release
```

## Troubleshooting

### Common Issues
1. **Flutter not found**: Add Flutter to PATH
2. **Dependency conflicts**: Run `flutter pub upgrade`
3. **Build failures**: Run `flutter clean && flutter pub get`
4. **iOS build issues**: Run `cd ios && pod install`

## License
This project is released under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact
Developer: Medouz
Project: 45min - Smart Fitness Coach
