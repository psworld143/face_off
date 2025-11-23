# FaceOFF - Advanced Face Analysis App

A modern Flutter application that uses AI to analyze facial features, determine attractiveness scores, identify best angles, and provide dermatological solutions.

## Features

- 📸 **Face Capture**: Take photos or select from gallery
- 🎯 **Attractiveness Analysis**: Get detailed facial attractiveness scoring (0-100)
- 📐 **Best Angle Detection**: Discover your most flattering angles with detailed descriptions
- 📊 **Feature Breakdown**: View detailed analysis of facial features (symmetry, skin quality, facial structure, etc.)
- 🏥 **Medical Solutions**: AI-powered dermatological recommendations and treatment suggestions
- 🎨 **Modern UI**: Beautiful, gradient-based interface with smooth animations

## Setup Instructions

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure API Keys

The app uses OpenAI APIs for face analysis and medical solutions. You need to configure your API key:

#### Setting up OpenAI API Key

The app uses environment variables for API key configuration. Set your OpenAI API key using one of these methods:

**Method 1: Using Dart Define (Recommended for Development)**
```bash
flutter run --dart-define=OPENAI_API_KEY=your_api_key_here
```

**Method 2: Using Environment Variables**
```bash
export OPENAI_API_KEY=your_api_key_here
flutter run
```

**Method 3: For Production Builds**
```bash
flutter build apk --dart-define=OPENAI_API_KEY=your_api_key_here
flutter build ios --dart-define=OPENAI_API_KEY=your_api_key_here
```

**Note**: 
- The app includes offline capabilities with local ML analysis and cached results
- If the API key is not set, the app will use local ML analysis or simulated data
- Never commit API keys to version control

### 3. Run the App

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── face_analysis_result.dart
│   └── medical_solution.dart
├── services/                  # API services
│   ├── face_analysis_service.dart
│   ├── medical_solution_service.dart
│   └── image_service.dart
├── screens/                   # UI screens
│   ├── home_screen.dart
│   └── results_screen.dart
└── widgets/                   # Reusable widgets
    ├── attractiveness_scale.dart
    ├── best_angle_card.dart
    ├── feature_breakdown.dart
    └── medical_solution_card.dart
```

## Permissions

The app requires the following permissions:

### Android
- Camera
- Read/Write External Storage

### iOS
- Camera Usage
- Photo Library Usage

These permissions are already configured in the respective manifest files.

## API Integration

### Face Analysis Service

The `FaceAnalysisService` analyzes facial images and returns:
- Attractiveness score (0-100)
- Best angle description
- Facial features breakdown
- Overall analysis

### Medical Solution Service

The `MedicalSolutionService` provides:
- Condition assessment
- Severity level
- Recommendations
- Treatment suggestions

## Customization

### Changing Colors

The app uses a purple-blue gradient theme. To customize:
- Edit `lib/main.dart` - Theme colors
- Edit individual widget files for specific color changes

### Modifying Analysis Logic

- `lib/services/face_analysis_service.dart` - Face analysis logic
- `lib/services/medical_solution_service.dart` - Medical solution logic

## Dependencies

- `image_picker` - For camera and gallery access
- `camera` - Camera functionality
- `http` - API calls
- `google_mlkit_face_detection` - Face detection (optional)
- `image` - Image processing
- `shimmer` - Loading animations

## Notes

- The app includes fallback/simulated data for demonstration when APIs are not configured
- Ensure you have proper API keys and network access for production use
- The app is optimized for portrait orientation

## License

This project is created for demonstration purposes.
