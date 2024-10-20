

## Overview

This project is built using Xcode and integrates Firebase for backend services. Follow the instructions below to set up your environment and run the project.

## Prerequisites

- Xcode (version 12 or later)
- CocoaPods (only if using for dependency management)
- A Firebase account

## Instructions

### 1. Clone the Repository

First, clone this repository to your local machine:

```bash
git clone https://github.com/MaxNMiller/CrowdMarks.git
cd CrowdMarks
```

### 2. Install Dependencies

use the package manager to install FirebaseFirestore and FirebaseStorage 

### 3. Set Up Firebase

1. **Create a Firebase Project:**
   - Go to the [Firebase Console](https://console.firebase.google.com/).
   - Click on "Add project" and follow the prompts to create a new project.

2. **Register your app:**
   - In the Firebase project overview, click on "Add app" and select iOS.
   - Enter your app's bundle ID (found in your Xcode project settings) and register the app.

3. **Download the `GoogleService-Info.plist` file:**
   - After registering the app, download the `GoogleService-Info.plist` file.

4. **Add the `GoogleService-Info.plist` to your Xcode project:**
   - Drag and drop the downloaded `GoogleService-Info.plist` file into the Xcode project ( I usually do this in the root directory of your project but i'm not sure if it matters).
   - Ensure that "Copy items if needed" is checked and that the file is added to the target.


### 4. Build and Run the Project

- Select your target device or simulator in Xcode.
- Click the Run button (or press Command + R) to build and run your project.

### 5. Troubleshooting

- Make sure you have set the correct bundle identifier in your Firebase project settings.
- If you encounter any issues with setting up the firebase, check the Firebase documentation for more detailed troubleshooting tips.

## License

This project is licensed under the MIT License. See the LICENSE file for details.
