# QLGD LHK Flutter Project (MVVM)

A Flutter project for a teaching management system using the MVVM architecture.

## Getting Started

### Installation

1.  Install dependencies:

    ```shell
    flutter pub get
    ```

2.  Generate code for Freezed/JsonSerializable models:

    ```shell
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

## Running the App

### Development Environment

```shell
flutter run -t lib/main_dev.dart --dart-define=BASE_URL=https://dev.api.example.com
```

### Staging Environment

```shell
flutter run -t lib/main_stg.dart --dart-define=BASE_URL=https://stg.api.example.com
```

### Production Environment

```shell
flutter run -t lib/main_prod.dart --dart-define=BASE_URL=https://api.example.com
```

## Building for Release

### Build for Web

```shell
flutter build web -t lib/main_prod.dart --release
```
