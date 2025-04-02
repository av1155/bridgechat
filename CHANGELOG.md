# Changelog

All notable changes to BridgeChat will be documented in this file.

## [Unreleased]

- Planned: Feature enhancements, performance optimizations, and additional platform support.

## [0.1.1] - 2025-04-02

### Added

- Group chat support with dynamic group name generation based on participants.
- Group settings screen with placeholder UI for name editing and leaving groups.
- Per-user translation logic in group chats using `originalText` and `translations` map.
- Translated recent message preview in recent conversations screen.
- Responsive design updates across all screens using `MediaQuery` constraints.
- Support for displaying timestamps, day markers, and grouped messages by date.
- Firebase Hosting configuration and CI workflow integration for Flutter web builds.
- Language preference selection during sign-up stored in Firestore.
- User-specific conversation deletion functionality.
- Auto-scroll behavior in chat on message send and load.

### Changed

- Chat bubble layout with max width constraints for better large-screen UX.
- Translation fallback logic refined to distinguish between individual and group chats.
- Message bubbles enhanced with gradients, shadows, and time display.
- `ChatScreen` refactored to support multiple participants and personalized headers.
- Routing updated to support cleaner navigation with usernames.
- GitHub Actions workflows improved for secret injection, Flutter setup, and web builds.

### Fixed

- Input field visibility by adding black borders to improve clarity.
- Flutter version mismatches and workflow errors related to `flutter-action`.
- Minor UI bugs and layout inconsistencies across chat and auth screens.
- `.gitignore` updated to exclude sensitive `secrets.dart` and included a sample template.

## [0.1.0] - 2025-04-01

### Added

- Initial project setup and documentation.
- Project Vision, SRS, System Architecture, Project Plan & Roadmap, Testing & QA, Deployment & Maintenance, and Developer Documentation files.
- Basic functionality for user registration, real-time messaging, and integrated translation (MVP).
