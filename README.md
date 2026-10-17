# Number Bond Challenge

A Flutter app for children to practice addition and subtraction by decomposing the second operand. It supports English, Spanish and French and saves the current child's profile and progress locally.

Answers check automatically after a short pause. Children can choose numbers from the grid or tap a part circle to open its picker. The challenge page starts with the question, a number-bond diagram with one whole-number circle branching to two answer circles, number choices and challenge actions. The full profile and rewards/progress cards follow below. An incomplete canonical place-value split automatically gains the missing empty circles; there are no manual Add Part or Remove Part controls. The full page scrolls on smaller screens.

A correct bond immediately reveals the result in the top equation, alongside the existing worked steps. Children do not enter a separate final answer. A new problem or learning retry starts with `?` again.

New profiles choose an age from 4–9. The corresponding year is saved so age updates each calendar year. Adaptive difficulty uses five recent normal outcomes at the current level; reviews preserve the normal level. Stars, badges, stickers and recent mistakes persist between sessions.

Generated addition and subtraction challenges, including reviews, exclude second operands exactly 10, 100 or 1000. First operands and other multiples such as 20 or 200 remain subject to the existing rules; this generation filter does not change answer validation.

## Development

```sh
flutter pub get
flutter analyze
flutter test --reporter expanded
dart run test_subtraction_check.dart
flutter run
```

For a signed iPhone build, configure the development team in Xcode, then run `flutter build ios --release`. Install with Xcode or Apple's device tools to preserve existing app data.

## Product and verification documents

- [Requirements](REQUIREMENTS.md)
- [Number-bond behavior and acceptance criteria](docs/NUMBER_BOND_STRATEGIES_PRD.md)
- [Arithmetic and interaction verification](docs/NUMBER_BOND_TEST_REPORT.md)
- [Birth-year age behavior](docs/BIRTH_YEAR_AGE.md)
- [Code and usability review](docs/CODE_REVIEW_REPORT.md)
- [Known logic gaps and recommended fixes](docs/LOGIC_REVIEW_2026-10-14.md)
- [Installed-version verification](docs/VERIFICATION_2026-10-16.md)

Multiple-profile selection, the separate practice mode, favorite-number weighting and generated insight cards are planned. The active learning flow is the adaptive challenge.
