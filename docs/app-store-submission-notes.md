# SAI GEETAMs - App Store Submission Checklist

## Before First Submission

### App Store Connect Setup
- Create new app in App Store Connect
- Bundle ID: com.saigeetams.app
- Primary Language: English
- Primary Category: Education
- Secondary Category: Music

### Age Rating Questionnaire
- Select age rating: 4+ (app is designed for children 4 and up with parental supervision)
- Made for Kids: Yes
- Age band: Ages 5-8, Ages 9-11 (select both as applicable)
- Note: Since this is a Kids category app, Apple has stricter review requirements
- No violence, no mature content, no gambling, no horror
- No third-party analytics or advertising SDKs
- No links out of the app except to privacy policy and terms

### Privacy Nutrition Labels (App Store Connect)
Fill in the following data types:

Data Used to Track You: NONE

Data Linked to You:
- Contact Info: Name, Email Address, Phone Number
- Identifiers: User ID

Data Not Linked to You: NONE

### Required URLs
- Privacy Policy URL: https://saigeetams.com/privacy (MUST be live before submission)
- Terms of Service URL: https://saigeetams.com/terms (MUST be live before submission)
- Support URL: https://saigeetams.com/support

### Screenshots Required
- 6.9" display (iPhone 16 Pro Max): minimum 3 screenshots
- 6.7" display (iPhone 16 Plus): minimum 3 screenshots
- 12.9" display (iPad Pro): minimum 3 screenshots if supporting iPad
- Show teacher, student, and parent views

### App Review Notes
Include a demo account in the review notes:
- Teacher login: demo@saigeetams.com / DemoPass123!
- Explain the three user roles (teacher, student, parent)
- Mention COPPA compliance and parental consent flow
- Mention this app is for Carnatic music class management

## Technical Requirements

### Privacy Manifest
- PrivacyInfo.xcprivacy is included in the project
- Declares UserDefaults and FileTimestamp API usage
- Declares all collected data types

### Info.plist Permission Descriptions
All required permission strings are set:
- NSCalendarsUsageDescription
- NSCalendarsFullAccessUsageDescription
- NSMicrophoneUsageDescription
- NSCameraUsageDescription
- NSPhotoLibraryUsageDescription
- NSFaceIDUsageDescription
- UIBackgroundModes: remote-notification

### Push Notifications
- Create APNs key in Apple Developer account
- Configure APNs key in Supabase project settings
- Test push notifications on a real device before submission

### Build Settings
- Minimum deployment target: iOS 17.0
- Build with latest Xcode and iOS SDK
- ITSAppUsesNonExemptEncryption: false (no custom encryption)
- CODE_SIGN_STYLE: Automatic
- DEVELOPMENT_TEAM: 98B7W2B79V

## After First Submission Approved

- Get Apple ID from App Store Connect > App Information
- Update AppSettings.swift: appStoreId = "YOUR_ACTUAL_ID"
- The force update pattern will activate from version 1.1 onward

## Annual COPPA Review

- Send annual privacy review notification to all parents
- Review and update privacy policy if needed
- Confirm all data collection practices are still accurate
