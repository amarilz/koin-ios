# koin-ios

Koin iOS is a lightweight SwiftUI client for [Koin](https://github.com/amarilz/koin), the Go backend for personal finance management.
The app allows you to record voice notes describing financial transactions and upload them to the Koin backend, where they are transcribed and processed.

## Features

- Record and play back audio notes.
- Manage recordings locally.
- Upload recordings sequentially to the backend.
- Automatically delete local recordings after successful upload.
- Configure the backend IP address and test connectivity.

## Requirements

- iOS 17+
- Xcode
- A running instance of the [Koin backend](https://github.com/amarilz/koin)

## Usage

Open the project in Xcode, configure the backend IP address in the app settings, and install the app on your iPhone.
This is a personal project intended for private use and is not distributed through the App Store.

## Building and Installing the IPA

Koin iOS is distributed privately using [AltStore Classic](https://altstore.io), without requiring a paid Apple Developer account.

### 1. Create an Xcode Archive

1. Open `koin.xcodeproj` in Xcode.
2. Select **Any iOS Device (arm64)** as the build destination.
3. Select **Product → Archive**.
4. Wait for the archive to complete.

There is no need to use **Distribute App**, as Xcode requires a paid Apple Developer membership for that export process.

### 2. Generate the IPA

From the project root, run:

```bash
chmod +x build-ipa.sh  # Only required once
./build-ipa.sh
```

The script automatically finds the latest Koin archive and packages it into:

```text
dist/Koin.ipa
```

The `dist/` directory is excluded from Git.

### 3. Install with AltStore

1. Make sure AltServer is running on your Mac.
2. Transfer `dist/Koin.ipa` to the Files app.
3. Open **AltStore Classic → My Apps → +**.
4. Select the IPA file to install or update Koin.

### 4. Refresh the App

With a free Apple Account, sideloaded apps normally expire after **7 days**.

To renew Koin without rebuilding it:

1. Keep AltServer running on your Mac.
2. Connect your Mac and iPhone to the same Wi-Fi network.
3. Open **AltStore Classic → My Apps → Refresh All**.

AltStore can also attempt automatic background refreshes.

**Note:** Creating a new IPA is only necessary when updating the app's code. Refreshing its signature does not require Xcode or a new build.