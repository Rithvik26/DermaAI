# DermaAI

DermaAI is a SwiftUI-based iOS application that helps dermatologists and healthcare providers manage patient data, track skin conditions, and get AI-powered analysis for diagnosis grouping and treatment recommendations.

## UI

<img width="351" alt="Screenshot 2024-12-17 at 7 32 35 PM" src="https://github.com/user-attachments/assets/767d4cbd-00ba-43df-9fe7-d59c0598bc65" />
<img width="351" alt="Screenshot 2024-12-17 at 7 32 45 PM" src="https://github.com/user-attachments/assets/b94d2223-cb9a-4ef7-b94d-45271d756a97" />
<img width="351" alt="Screenshot 2024-12-17 at 7 32 52 PM" src="https://github.com/user-attachments/assets/4250748a-c690-4886-8395-12901605c9f2" />
<img width="351" alt="Screenshot 2024-12-18 at 7 25 34 AM" src="https://github.com/user-attachments/assets/e7cb6454-89d2-4aa9-937d-fcb453d41c1c" />
<img width="351" alt="Screenshot 2024-12-18 at 7 25 44 AM" src="https://github.com/user-attachments/assets/453fec81-2258-473c-bc01-ce4921c84181" />
<img width="351" alt="Screenshot 2024-12-18 at 7 26 02 AM" src="https://github.com/user-attachments/assets/4b5a9401-6757-4d5e-b1ec-89b345d00e8d" />

## Features

- **Patient Management**
  - Add and edit patient records
  - Track diagnosis notes
  - Manage medications with dosage and frequency
  - View detailed patient histories

- **AI-Powered Analysis**

  - Group patients by common skin conditions
  - Get treatment recommendations
  - Batch analysis of multiple patient records
  - API connection testing functionality

- **Medication Tracking**
  - Record multiple medications per patient
  - Track dosage information
  - Monitor treatment frequencies
  - Easy medication management interface

## Technical Architecture

The app follows the MVVM (Model-View-ViewModel) architecture pattern and is built using:

- SwiftUI for the user interface
- Combine framework for reactive programming
- Claude API for AI-powered analysis
- URLSession for network requests

### Key Components

- `PatientViewModel`: Manages patient data and handles API communication
- `AnalyzerView`: Provides the AI analysis interface
- `Patient` and `Medication` models: Core data structures
- `ClaudeAPIService`: Handles API integration

## Requirements

- iOS 15.0 or later
- Xcode 13.0 or later
- Swift 5.5 or later
- Valid Claude API key

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/DermaAI.git
```

2. Open `DermaAI.xcodeproj` in Xcode

3. Add your Claude API key:
   - Open `PatientViewModel.swift`
   - Replace the `apiKey` value with your actual API key

4. Build and run the project

## Configuration

The app uses the Claude API for analysis. To configure:

1. Ensure you have a valid API key from Anthropic
2. Set the API key in `PatientViewModel.swift`
3. Test the API connection using the built-in test function

## Usage

### Adding a New Patient

1. Tap the '+' button in the main view
2. Enter patient information:
   - Name
   - Diagnosis notes
   - Medications (if any)
3. Save the patient record

### Running Analysis

1. Tap the waveform icon in the main view
2. Click "Start Batch Analysis"
3. View grouped results and recommendations

## Security

- The app does not store the API key in user defaults or on device
- All network communications use HTTPS
- Patient data is stored locally on the device

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built using [Claude API](https://anthropic.com) for AI analysis
- Uses [SwiftUI](https://developer.apple.com/xcode/swiftui/) for the user interface
- Inspired by the need for better dermatological diagnostic tools

## Support

For support, please open an issue in the GitHub repository or contact the maintainers.

## Roadmap

- [ ] Add support for image uploads
- [ ] Implement local data persistence
- [ ] Add export functionality for patient records
- [ ] Enhance AI analysis with more detailed recommendations
- [ ] Add support for multiple languages

## Author



Rithvik Golthi

## Project Status

Active development - Contributions welcome
