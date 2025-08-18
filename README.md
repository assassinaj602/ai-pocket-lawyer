# AI Pocket Lawyer 🏛️⚖️

An AI-powered legal guidance app that provides everyday people in the US and UK with accessible legal advice, document analysis, and case management tools.

## 📱 Features

### 🤖 AI Legal Assistant
- **Smart Legal Analysis**: Get instant legal guidance using advanced AI
- **Document OCR**: Upload and analyze legal documents, contracts, and notices
- **Voice Input**: Ask questions using speech-to-text
- **Jurisdiction-Specific**: Tailored advice for US and UK legal systems

### � Case Management
- **Evidence Vault**: Securely store and organize case-related documents
- **Case Tracking**: Monitor deadlines, attachments, and case progress
- **PDF Export**: Generate shareable case summaries
- **Deadline Reminders**: Never miss important legal deadlines

### � Core Functionality
- **Clean AI Responses**: Professional, well-formatted legal guidance
- **Clickable Links**: Direct access to relevant legal resources
- **Dark/Light Themes**: Comfortable viewing in any environment
- **Offline Storage**: Access your cases and analyses without internet

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.7.2 or higher)
- Dart SDK
- Android Studio / VS Code
- OpenRouter API key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/assassinaj602/ai-pocket-lawyer.git
   cd ai-pocket-lawyer
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   Create a `.env` file in the root directory:
   ```env
   OPENROUTER_API_KEY=your_api_key_here
   OPENROUTER_MODEL=deepseek/deepseek-chat-v3-0324:free
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📸 Screenshots

### Home Screen
![Home Screen](assets/images/screenshot_home.png)
*Main interface for asking legal questions with voice input and image upload*

### AI Analysis Results
![AI Analysis](assets/images/screenshot_analysis.png)
*Clean, professional AI responses with actionable legal guidance*

### Case Management
![Cases Screen](assets/images/screenshot_cases.png)
*Organize and track your legal cases and evidence*

### Case Details
![Case Details](assets/images/screenshot_case_details.png)
*Detailed view of case information, deadlines, and attachments*

### Settings
![Settings](assets/images/screenshot_settings.png)
*Configure API keys, themes, and jurisdiction preferences*

### Document Analysis
![Document OCR](assets/images/screenshot_document_ocr.png)
*Upload and analyze legal documents with OCR technology*

## 🏗️ Architecture

### Tech Stack
- **Frontend**: Flutter/Dart
- **State Management**: Provider
- **Local Storage**: Hive
- **AI Integration**: OpenRouter API (DeepSeek model)
- **OCR**: Google ML Kit Text Recognition
- **PDF Generation**: Flutter PDF
- **File Handling**: File Picker
- **Speech Recognition**: Speech to Text

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── analysis_result.dart
│   ├── case_models.dart
│   └── legal_models.dart
├── providers/                # State management
│   ├── legal_analysis_provider.dart
│   ├── case_provider.dart
│   └── app_settings_provider.dart
├── screens/                  # UI screens
│   ├── splash_screen.dart
│   ├── get_started_screen.dart
│   ├── home_screen.dart
│   ├── results_screen.dart
│   ├── settings_screen.dart
│   └── cases/
├── services/                 # Business logic
│   ├── storage_service.dart
│   ├── ocr_service.dart
│   └── legal_data_service.dart
└── widgets/                  # Reusable components
    └── attachment_picker.dart
```

## 🔧 Configuration

### API Setup
1. Sign up for [OpenRouter](https://openrouter.ai/)
2. Get your API key
3. Add it to `.env` file or app settings

### Supported Jurisdictions
- **United States**: Federal and state-level legal guidance
- **United Kingdom**: England, Wales, Scotland, and Northern Ireland

## 📱 Building for Production

### Debug APK
```bash
flutter build apk --debug --dart-define=OPENROUTER_API_KEY=your_api_key_here
```

### Release APK
```bash
flutter build apk --release --dart-define=OPENROUTER_API_KEY=your_api_key_here --dart-define=OPENROUTER_MODEL=deepseek/deepseek-chat-v3-0324:free
```

### App Bundle (Play Store)
```bash
flutter build appbundle --release --dart-define=OPENROUTER_API_KEY=your_api_key_here
```

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter/Dart style guidelines
- Add tests for new features
- Update documentation as needed
- Ensure compatibility with both Android and iOS

## 📄 Legal Disclaimer

This app provides general legal information and should not be considered as legal advice. Always consult with a qualified attorney for specific legal matters. The developers are not responsible for any legal decisions made based on the app's guidance.

## � Privacy & Security

- **Local Storage**: Case data is stored locally on your device
- **API Communication**: Only question text is sent to AI services
- **No Personal Data Collection**: We don't collect or store personal information
- **Secure Document Handling**: Documents are processed locally when possible

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🛠️ Troubleshooting

### Common Issues

**Build Errors**
```bash
flutter clean
flutter pub get
flutter run
```

**API Key Issues**
- Verify your OpenRouter API key is correct
- Check your account balance and usage limits
- Ensure the key is properly set in `.env` or app settings

**OCR Not Working**
- Ensure proper permissions for camera/storage
- Check image file formats (JPG, PNG supported)
- Verify file size limitations

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/assassinaj602/ai-pocket-lawyer/issues)
- **Discussions**: [GitHub Discussions](https://github.com/assassinaj602/ai-pocket-lawyer/discussions)
- **Email**: support@aipocketlawyer.com

## 🚀 Roadmap

- [ ] Multi-language support
- [ ] Advanced OCR with table extraction
- [ ] Legal form templates
- [ ] Court filing assistance
- [ ] Lawyer referral network
- [ ] Video consultation integration

## 📊 Stats

![GitHub stars](https://img.shields.io/github/stars/assassinaj602/ai-pocket-lawyer)
![GitHub forks](https://img.shields.io/github/forks/assassinaj602/ai-pocket-lawyer)
![GitHub issues](https://img.shields.io/github/issues/assassinaj602/ai-pocket-lawyer)
![GitHub license](https://img.shields.io/github/license/assassinaj602/ai-pocket-lawyer)

---

**Made with ❤️ for accessible legal justice**
