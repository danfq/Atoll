# DynamicIsland

<p align="center">
  <img src="https://github.com/Ebullioscopic/DynamicIsland/blob/main/dynamic-island.jpeg" alt="DynamicIsland Logo" width="200"/>
</p>

> **DynamicIsland** enhances the notch on your MacBook M3 Pro with interactive, customizable widgets, transforming it into a dynamic control center for multitasking, notifications, and more.

---

<details open>
<summary>📑 Table of Contents</summary>

- [Features](#features)
- [Demo](#demo)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
  - [Basic Controls](#basic-controls)
  - [Customization Options](#customization-options)
- [Configuration](#configuration)
- [Roadmap](#roadmap)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgments](#acknowledgments)
- [Contributors](#contributors)

</details>

---

## 🌟 Features

- **Music Controls**: Play, pause, and skip tracks from the notch area.
- **Battery Status**: Real-time battery percentage and low-battery alerts.
- **Calendar Reminders**: Displays upcoming events directly in the notch.
- **Weather Updates**: Get current weather conditions at a glance.
- **Multitasking Tools**: Quickly switch between open applications.
- **Customizable Themes**: Light, dark, and custom color themes.
- **Gesture Support**: Use gestures for quick actions.

## 🎥 Demo

Check out a quick demo of DynamicIsland in action:

![DynamicIsland Demo](https://github.com/Ebullioscopic/DynamicIsland/raw/main/demo.gif)

---

## 🚀 Getting Started

These instructions will get you a copy of **DynamicIsland** up and running on your local machine.

### Prerequisites

- **macOS Ventura 14.2** or later.
- **Xcode 15.0** or later.
- **SwiftUI** and **Objective-C** frameworks installed.
- **Make** installed for build automation.

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/Ebullioscopic/DynamicIsland.git
   cd DynamicIsland
   ```

2. **Install Dependencies**
   Make sure you have all required libraries and frameworks installed. Use Homebrew for some dependencies if needed:
   ```bash
   brew install make
   ```

3. **Build and Run the Project**
   Open the project in Xcode, select your target device, and run:
   ```bash
   open DynamicIsland.xcodeproj
   ```

4. **Run the App in Xcode**
   Build and run the app from Xcode by pressing `Cmd + R`:
   - If prompted by macOS, allow permissions for **Privacy & Security**.

---

## 📖 Usage

Once **DynamicIsland** is installed and running, it will display widgets and controls in the MacBook's notch area. Here are some usage tips and customization options.

### Basic Controls

- **Music Controls**: Hover over the notch and use on-screen buttons to control playback.
- **Battery Status**: A battery indicator will be displayed in the notch. Low battery alerts will appear automatically.
- **Weather Widget**: Displays current weather for your location (requires location access).
- **App Switcher**: Swipe gestures allow you to quickly switch between open applications.

### Customization Options

To personalize your DynamicIsland experience:

1. **Open Preferences**: Access the Preferences pane by long-pressing on the notch area.
2. **Themes**: Choose between **light**, **dark**, or **system adaptive** themes.
3. **Widget Settings**: Enable/disable specific widgets, adjust sizes, and set display preferences.
4. **Gestures**: Customize swipe, tap, and long-press actions for app switching and widget controls.

---

## ⚙️ Configuration

Configuration settings can be found in the `config.json` file located in the root directory.

### `config.json` Example

```json
{
  "theme": "dark",
  "batteryWidget": true,
  "musicWidget": true,
  "weatherWidget": true,
  "gestureSettings": {
    "tap": "toggleMusic",
    "swipeLeft": "previousApp",
    "swipeRight": "nextApp",
    "longPress": "openSettings"
  }
}
```

- **`theme`**: Options are `"light"`, `"dark"`, or `"auto"`.
- **`batteryWidget`, `musicWidget`, `weatherWidget`**: Toggle visibility for each widget.
- **`gestureSettings`**: Assign actions to tap, swipe, and long-press gestures.

---

## 🚧 Roadmap

Planned updates for future releases:

- [ ] **Advanced Calendar Integration**: Add support for weekly and monthly views.
- [ ] **Customizable Shortcuts**: Create custom app shortcuts.
- [ ] **Additional Widget Support**: Add widgets for finance, fitness, and more.
- [ ] **Voice Commands**: Enable Siri shortcuts for quick commands.
- [ ] **Animation Improvements**: Smooth animations for a more polished UI.

---

## 🔧 Troubleshooting

### Common Issues

- **Permissions**: Go to **System Preferences > Security & Privacy** to manually enable permissions if the app fails to start.
- **Widgets Not Displaying**: Ensure your `config.json` file has valid settings, then restart the app.
- **Build Errors in Xcode**: Run `make clean` to reset the project, then re-build.

### Useful Commands

- **Clean Build Files**:
  ```bash
  make clean
  ```
- **Reset Configurations**:
  ```bash
  rm config.json && cp config.default.json config.json
  ```

---

## 🤝 Contributing

We welcome contributions from the community! Follow the steps below to contribute:

1. **Fork the repository**.
2. **Clone Your Fork**:
    ```bash
    git clone https://github.com/yourusername/DynamicIsland.git
    cd DynamicIsland
    ```
3. **Create a New Branch**:
    ```bash
    git checkout -b feature/YourFeatureName
    ```
4. **Make Your Changes** and **Commit**:
    ```bash
    git commit -m "Added new feature"
    ```
5. **Push to Your Fork**:
    ```bash
    git push origin feature/YourFeatureName
    ```
6. **Create a Pull Request**: Head to the original repository and open a pull request.

For major changes, please open an issue first to discuss what you’d like to change.

---

## 📜 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 🏆 Acknowledgments

Special thanks to:
- **Apple Design Principles** for inspiration.
- **Boring Notch** project for initial ideas.

---

## 👥 Contributors

<table>
  <tr>
    <td align="center"><a href="https://github.com/Ebullioscopic"><img src="https://github.com/Ebullioscopic.png" width="100px;" alt=""/><br /><sub><b>Ebullioscopic</b></sub></a><br />Creator</td>
  </tr>
</table>