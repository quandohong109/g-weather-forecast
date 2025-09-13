# G-Weather-Forecast

A simple weather forecast web application built with Flutter. This project allows users to search for weather information by city, view current conditions and a 4-day forecast, and subscribe to daily weather updates via email.

This project was built as a demonstration of skills in Flutter and Firebase.

## Live Demo

The application is deployed and accessible live on Firebase Hosting:

**[https://g-weather-forecast-v1.web.app](https://g-weather-forecast-v1.web.app)**

## Features

- **City Search**: Search for any city worldwide to get weather data.
- **Current Weather**: Displays current temperature, wind speed, humidity, and weather conditions.
- **Forecast**: Shows the weather forecast for the next 4-13 days.
- **Email Subscriptions**:
    - Subscribe with an email address to receive daily weather updates for a chosen city.
    - Unsubscribe from the service.
    - **Email Confirmation**: Both subscription and unsubscription actions require email verification for security.
- **Deployment**: The web application is deployed live using Firebase Hosting.

## Technologies Used

- **Frontend**: Flutter
- **Backend & Hosting**:
    - **Firebase Hosting**: For deploying the web application.
    - **Cloud Firestore**: As the primary database to store user subscriptions.
    - **Cloud Functions for Firebase (v2)**: For handling backend logic, such as sending verification emails and managing subscriptions.
    - **Trigger Email from Firestore Extension**: To send emails via SMTP.
- **API**: [WeatherAPI.com](https://www.weatherapi.com/) for all weather-related data.
- **State Management**: `flutter_bloc`

## Local Setup and Installation

To run this project locally, follow these steps:

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
- [Node.js](https://nodejs.org/en/) and [npm](https://www.npmjs.com/) installed.
- [Firebase CLI](https://firebase.google.com/docs/cli) installed (`npm install -g firebase-tools`).
- A Firebase project with Firestore, Cloud Functions, and Hosting enabled.
- An API key from [WeatherAPI.com](https://www.weatherapi.com/).

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd g-weather-forecast
```

### 2. Configure Firebase

1.  Run `flutterfire configure` and connect the project to your Firebase project. This will generate a `lib/firebase_options.dart` file.
2.  Navigate to the `functions` directory and install the dependencies:
    ```bash
    cd functions
    npm install
    cd ..
    ```

### 3. Set Up Environment Variables (Secrets)

The Cloud Functions require a secret API key from WeatherAPI.com.

1.  Enable the Secret Manager API in your Google Cloud project.
2.  Set the secret using the Firebase CLI:
    ```bash
    firebase functions:secrets:set WEATHER_API_KEY
    ```
    When prompted, enter your API key from WeatherAPI.com.

### 4. Run the Application

You can run the Flutter web app in development mode:

```bash
flutter run -d chrome
```

### 5. Deploy Cloud Functions

To make the subscription service work, you need to deploy the Cloud Functions:

```bash
firebase deploy --only functions
```

