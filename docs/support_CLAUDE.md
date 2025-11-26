# Pismo Support - Cultural & Technical Context

## About This Document

This document provides comprehensive context about Pismo for AI assistants, developers, and contributors. It covers the cultural significance, technical implementation, and philosophical foundations of the project.

---

## Cultural Foundations

### The Cyrillic Script: A Bridge Between Cultures

#### Historical Origins (9th Century Bulgaria)

The Cyrillic script was created in the **First Bulgarian Empire** during the 9th century. Saints Cyril and Methodius, along with their disciples (notably Saints Clement and Naum of Ohrid), developed this writing system to spread Christianity and literacy among Slavic peoples.

**Key Historical Points:**
- **863 AD**: Creation of the Glagolitic alphabet by Saints Cyril and Methodius
- **Late 9th Century**: Development of Cyrillic script in Preslav and Ohrid literary schools
- **Bulgaria's Role**: The Preslav Literary School in Bulgaria is considered the birthplace of the Cyrillic alphabet as we know it today

#### Languages Using Cyrillic Today

The Cyrillic script is used by approximately **250 million people** worldwide:

| Language | Speakers | Notes |
|----------|----------|-------|
| Russian | ~150M native | Largest Cyrillic-using population |
| Ukrainian | ~40M native | Distinct orthographic traditions |
| Bulgarian | ~8M native | Birthplace of Cyrillic |
| Serbian | ~9M native | Uses both Cyrillic and Latin scripts |
| Belarusian | ~5M native | Rich literary tradition |
| Macedonian | ~2M native | South Slavic language |
| Mongolian | ~3M native | Adopted in 1940s |
| Kazakh | ~13M native | Transitioning to Latin script |
| Others | Various | Kyrgyz, Tajik, etc. |

### The Orthodox Church Connection

The spread of Cyrillic is deeply intertwined with **Eastern Orthodox Christianity**:

- **Liturgical Language**: Church Slavonic, written in Cyrillic, remains the liturgical language of many Orthodox churches
- **Cultural Transmission**: Monasteries preserved and spread both the script and Orthodox traditions
- **Japan Connection**: The Japanese Orthodox Church (日本ハリストス正教会) uses Cyrillic-based Church Slavonic in some liturgical contexts

### Japan and Cyrillic: Unexpected Connections

#### Historical Ties
- **Russian-Japanese Relations**: From the first Japanese castaways in Russia (Dembei, 1697) to modern cultural exchange
- **Orthodox Christianity in Japan**: Introduced by Saint Nicholas of Japan (ニコライ・カサートキン) in 1861
- **Academic Interest**: Japanese Slavic studies have a rich tradition dating back to the Meiji era

#### Modern Connections
- Japanese anime/manga featuring Slavic themes
- Growing interest in Slavic languages among Japanese learners
- Cultural exchange programs between Japan and Slavic nations

---

## Technical Implementation

### Architecture Overview

```
Pismo/
├── iOS/                    # iOS/iPadOS Implementation
│   ├── MainApp/            # Main application
│   ├── Keyboard/           # Keyboard extension
│   └── AzooKeyCore/        # Core library (based on azooKey)
└── Android/                # Android Implementation (planned)
```

### Core Technology Stack

#### iOS/iPadOS
- **Language**: Swift 5.9+
- **Minimum iOS**: 15.0
- **Base Project**: [azooKey](https://github.com/ensan-hcl/azooKey) by Keita Miwa (ensan)
- **Input Method**: Custom keyboard extension using Apple's App Extension framework

#### Key Features
- **Cyrillic-to-Japanese Conversion**: Maps Cyrillic characters to Japanese phonetic equivalents
- **Multiple Keyboard Layouts**: Russian, Ukrainian, Belarusian, Bulgarian, Serbian
- **Hiragana/Katakana Support**: Full Japanese syllabary output
- **Predictive Text**: Japanese language prediction

### Conversion Logic

The keyboard implements a phonetic mapping system:

```
Cyrillic Input → Romaji Equivalent → Japanese Output

Example:
К → k
А → a
КА → ka → か (hiragana) / カ (katakana)
```

### Privacy & Security

- **No Data Collection**: The keyboard does not collect or transmit user input
- **Local Processing**: All text conversion happens on-device
- **No Network Access**: Keyboard extension operates offline
- **Full Access Not Required**: Basic functionality works without full access permissions

---

## Philosophical Foundations

### No Political Stance

**Important Declaration**: Pismo takes no political stance regarding any nation, conflict, or territorial dispute involving Cyrillic-using countries.

The project's sole focus is:
1. **Linguistic Interest**: Appreciation for Cyrillic as a writing system
2. **Cultural Bridge**: Connecting Japanese speakers with Slavic languages
3. **Educational Tool**: Supporting language learners and researchers
4. **Religious Studies**: Assisting those studying Orthodox Christianity and Church Slavonic

### Inclusivity

Pismo celebrates the diversity of Cyrillic-using cultures:
- All languages are treated with equal respect
- No language is presented as "primary" or "superior"
- Cultural contributions of all Cyrillic nations are acknowledged

---

## Target Audiences

### Primary Users

1. **Japanese Learners of Slavic Languages**
   - Students studying Russian, Ukrainian, Bulgarian, etc.
   - Travelers preparing for visits to Slavic countries
   - Business professionals working with Slavic partners

2. **Slavic Speakers Learning Japanese**
   - Native Cyrillic users studying Japanese
   - Those who prefer Cyrillic input over Romaji
   - Bilingual individuals comfortable with Cyrillic keyboards

3. **Religious Scholars**
   - Researchers of Eastern Orthodox Christianity
   - Students of Church Slavonic
   - Members of the Japanese Orthodox Church

4. **Linguists & Academics**
   - Comparative linguistics researchers
   - Slavic studies scholars
   - Input method researchers

### Secondary Users

- Hobbyists interested in writing systems
- Developers interested in input method technology
- Cultural enthusiasts exploring Slavic heritage

---

## App Store / Play Store Compliance

### Required Elements

#### Privacy Policy
- Clear statement of no data collection
- Explanation of keyboard permissions
- Contact information for privacy inquiries

#### Age Rating
- 4+ (suitable for all ages)
- No user-generated content
- No social features

#### Content Guidelines
- Educational/utility category
- No political content
- No controversial material

### Accessibility

- VoiceOver support (iOS)
- Dynamic Type support
- High contrast mode compatibility
- Keyboard navigation support

---

## Support Resources

### For Users
- GitHub Issues: Bug reports and feature requests
- GitHub Discussions: Community Q&A
- Email: [Support email to be added]

### For Developers
- Contribution guidelines in CONTRIBUTING.md
- Code of conduct in CODE_OF_CONDUCT.md
- Technical documentation in /docs

---

## Acknowledgments

### Open Source Foundation
This project is built upon **azooKey** by Keita Miwa (ensan), an excellent open-source Japanese keyboard for iOS. We are deeply grateful for this foundation.

### Cultural Consultants
We acknowledge the importance of cultural sensitivity and welcome feedback from native speakers of all Cyrillic-using languages.

### Community
Thank you to all users, contributors, and supporters who help make Pismo better.

---

## Version History

| Version | Date | Notes |
|---------|------|-------|
| 1.0.0 | 2025 | Initial release |

---

*This document is maintained by the Pismo development team and is intended for AI assistants, developers, and contributors who need comprehensive context about the project.*
