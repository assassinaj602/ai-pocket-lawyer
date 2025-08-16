# 🏛️ AI Pocket Lawyer

A comprehensive Flutter mobile application that provides intelligent legal guidance using AI technology. Get professional legal analysis, document assistance, and expert advice right from your pocket.

## ✨ Features

- **🤖 AI Legal Analysis** - Powered by DeepSeek AI for comprehensive legal guidance
- **📚 Legal Document Library** - Access to templates and legal forms
- **🌍 Multi-Jurisdiction Support** - US and UK legal frameworks
- **🔍 Smart Legal Search** - Find relevant laws and precedents
- **📄 Document Generation** - Create legal letters and documents
- **🗣️ Voice Interface** - Speech-to-text legal queries
- **💾 Case Management** - Save and organize your legal analyses

## 🛠️ Technology Stack

- **Framework:** Flutter 3.24+
- **AI Integration:** OpenRouter API with DeepSeek model
- **State Management:** Provider
- **HTTP Client:** Dio
- **Voice Features:** Speech-to-text, Text-to-speech
- **Local Storage:** SharedPreferences
- **Document Export:** PDF generation

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.24.0 or higher
- Dart SDK 3.5.0 or higher
- Android Studio / VS Code
- OpenRouter API key

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/ai-pocket-lawyer.git
   cd ai-pocket-lawyer
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables:**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and add your OpenRouter API key:
   ```env
   OPENROUTER_API_KEY=your_actual_api_key_here
   OPENROUTER_MODEL=deepseek/deepseek-chat-v3-0324:free
   ```

4. **Run the application:**
   ```bash
   flutter run
   ```

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

## 🔧 Configuration

### API Configuration

The app supports multiple configuration methods:

1. **Development (.env file):**
   - Copy `.env.example` to `.env`
   - Add your API credentials

2. **Production (dart-define):**
   - Pass API key during build using `--dart-define`
   - Keeps sensitive data out of source control

3. **Environment Variables:**
   - `OPENROUTER_API_KEY`: Your OpenRouter API key
   - `OPENROUTER_MODEL`: AI model to use (default: deepseek/deepseek-chat-v3-0324:free)

## 📖 Usage

### Basic Legal Query
1. Open the app
2. Select your jurisdiction (US/UK)
3. Choose a legal category or type your question
4. Get comprehensive AI-powered legal analysis

### Document Generation
1. Navigate to Document Templates
2. Select the type of document needed
3. Fill in the required information
4. Generate and export as PDF

### Voice Interface
1. Tap the microphone icon
2. Speak your legal question
3. Get voice responses with text-to-speech

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── legal_models.dart
│   └── analysis_result.dart
├── providers/                # State management
│   └── legal_analysis_provider.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── legal_analysis_screen.dart
│   └── document_templates_screen.dart
├── services/                 # Business logic
│   ├── ai_legal_service.dart
│   ├── legal_data_service.dart
│   └── web_scraping_service.dart
└── widgets/                  # Reusable components
    ├── legal_category_card.dart
    └── analysis_result_card.dart
```

## 🔒 Security

- ✅ API keys are never hardcoded in source code
- ✅ Environment variables are excluded from version control
- ✅ Secure build process using dart-define
- ✅ Input validation and sanitization
- ✅ HTTPS-only API communication

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## ⚖️ Legal Disclaimer

This application provides legal information for educational purposes only and does not constitute legal advice. Always consult with a qualified attorney for specific legal matters. The developers are not responsible for any legal decisions made based on information provided by this application.

## 🔗 Links

- **OpenRouter:** [https://openrouter.ai/](https://openrouter.ai/)
- **Flutter Documentation:** [https://flutter.dev/docs](https://flutter.dev/docs)
- **DeepSeek AI:** [https://deepseek.com/](https://deepseek.com/)

## 📞 Support

For support and questions:
- Create an issue on GitHub
- Email: support@aipocketlawyer.com

---

**Made with ❤️ using Flutter and AI technology**
   - `OPENROUTER_MODEL`: AI model to use (default: deepseek/deepseek-chat-v3-0324:free)

## Key Legal Areas Covered

- Tenant Rights & Housing Issues
- Employment Law & Workplace Rights
- Consumer Protection
- Contract Disputes
- Harassment & Discrimination
- Small Claims & Debt Issues

## Getting Started

### Prerequisites

- Flutter SDK 3.7.2 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository
2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Optional: OpenAI API Integration

For enhanced AI responses, you can add your OpenAI API key:

1. Get an API key from [OpenAI Platform](https://platform.openai.com/)
2. Open the app settings
3. Enter your API key in the "AI Configuration" section

**Note**: The app works in demo mode without an API key, using curated legal data.

## Usage

1. **Ask Your Legal Question**: Type or speak your legal problem in plain language
2. **Review Your Rights**: Get a clear summary of your legal rights
3. **Follow Action Steps**: See specific steps you can take
4. **Generate Letters**: Create professional legal correspondence
5. **Find Local Help**: Contact free legal aid organizations

## Example Queries

- "My landlord entered my apartment without notice"
- "I was fired after taking medical leave"
- "A company won't refund my faulty purchase"
- "My employer is discriminating against me"
- "I need to write a complaint letter about poor service"

## Legal Disclaimer

**IMPORTANT**: This app provides general legal information only and is NOT a substitute for professional legal advice.

- Information may not be current or complete
- Laws vary by jurisdiction and change frequently
- Individual circumstances affect legal outcomes
- This app does not create an attorney-client relationship

**ALWAYS** consult with a qualified attorney for:
- Specific legal advice
- Court proceedings
- Contract review
- Any serious legal matter

---

**Disclaimer**: This application is for informational purposes only and does not constitute legal advice. Always consult with qualified legal professionals for specific legal matters.
