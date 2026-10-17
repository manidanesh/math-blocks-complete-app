# Math Blocks Complete App - Requirements Document

## Project Overview
An adaptive math learning app for children that teaches addition and subtraction using the Number Bond strategy. The app dynamically adjusts difficulty based on performance and provides engaging, educational experiences.

## Core Features

### 1. User Profile Management
- **Profile Creation**: Select an age from 4–9, avatar and language
- **Age Selection**: New profiles offer ages 4–9 directly and store the corresponding birth year for annual age updates; profile birth-year editing supports estimated ages 0–100 so existing children can keep using their profiles as they grow
- **Calculated Age**: Display the current local calendar year minus birth year; this is an estimate that changes January 1 because the app does not collect a birth month or day
- **Automatic Refresh**: Calculate age when loading a profile, reopening/resuming the app, and crossing a calendar-year boundary while the app stays open
- **Existing Profiles**: Preserve saved age until the user supplies a birth year; do not invent a birth year from old age or profile creation time
- **Persistence**: Store birth year locally and preserve it during profile edits, progress updates, and progress resets
- **Multiple Profiles (Planned)**: Add a profile chooser and management for multiple children per device; the current interface uses one active profile
- **Profile History**: Track performance, failed attempts, and progress over time
- **Insights Display**: Show learning patterns and performance analytics

### 2. Adaptive Challenge System
- **Dynamic Difficulty**: Adjusts problem difficulty based on recent performance
- **Performance Tracking**: Monitors accuracy, time taken, hint usage
- **Level Progression**: 4 difficulty levels with automatic advancement/regression
- **Review Problems**: Injects easier problems when struggling

### 3. Number Bond Strategy Teaching

#### 3.1 Problem Generation Rules
- **Excluded Second Operands**: Normal and review challenges at every level must never use a second operand exactly 10, 100 or 1000, for either addition or subtraction. This does not exclude those values as first operands or exclude other multiples such as 20 and 200; existing level, crossing and subtraction-validity rules still apply. Current operands are capped at 999, so 1000 is explicitly reserved by this rule for future ranges.

**Addition Problems:**
- Must "cross the next 10" (e.g., 47 + 6, not 45 + 3)
- Teach breaking the second number to make ten first as the default strategy
- Example: 47 + 6 → 6 breaks into 3 + 3 → 47 + 3 + 3 = 50 + 3 = 53
- Accept any correct decomposition of the second number into two or more nonnegative parts, including round chunks and place value

**Subtraction Problems:**
- Standard generated problems must "cross the ten boundary" (e.g., 42 - 7, not 42 - 1); Level 1 retains the solvable zero-ending stretch examples below
- Teach breaking the second number to reach the next lower ten first as the default strategy
- Example: 42 - 7 → 7 breaks into 2 + 5 → 42 - 2 - 5 = 40 - 5 = 35
- Also accept a correct split containing one or more positive multiples of 10 and at most one non-round remainder, in any order

#### 3.2 Special Rules for Numbers Ending in 0
- Standard crossing subtraction generation excludes first operands ending in zero
- Addition may use a zero-ending first operand when the second operand exceeds 10, allowing a positive remainder after reaching the next ten
- Preserve legacy validation of correct two-part splits starting with 10 or with the integer half of the second operand
- Level 1 stretch exceptions include 20 - 8 with 4 + 4 and 20 - 9 with 4 + 5; both are solvable under the existing even-split rule

#### 3.3 Flexible Decompositions and Order
- Preserve existing valid two-part subtraction rules, including reaching the lower ten and special cases for first operands ending in zero
- Addition accepts any correct two-or-more-part sum; the new round-chunk and place-value subtraction methods accept any order
- 4 + 14 accepts 6 + 8, 10 + 4, and 4 + 10 as splits of 14
- 29 - 15 accepts 9 + 6, 10 + 5, and 5 + 10 as splits of 15
- 24 accepts both 10 + 14 and 20 + 4; 120 accepts 100 + 20; 235 accepts 200 + 30 + 5 and their permutations
- Support any operand size handled by the app, including 100 and above; keep the first operand unchanged
- Example: 110 + 235 → 110 + 200 + 30 + 5 = 345
- See [Flexible Number Bonds Product Requirement](docs/NUMBER_BOND_STRATEGIES_PRD.md) for detailed acceptance and feedback rules

### 4. Difficulty Levels

#### Level 1: Introductory addition and subtraction
- Addition review/stretch examples use single-digit operands; standard examples use first operands 11-19 and second operands up to 15
- Addition must cross the next ten with a positive remainder
- Subtraction uses two-digit minus single-digit crossing problems, plus the supported 20 - 8 and 20 - 9 stretch examples
- Examples: 7 + 5 = 12, 15 - 8 = 7

#### Level 2: 2-digit operations
- Addition: 10-99 + 1-9 (crossing next 10)
- Addition excludes first operands ending in 0 or 1, which cannot cross with a positive remainder using a single-digit second operand
- Subtraction: 20-99 - 6-18 (crossing ten boundary)
- Examples: 47 + 6, 42 - 7

#### Level 3: 2-digit + 2-digit
- Range: 10-99 + 10-99 (with crossing)
- Range: 50-99 - 6-18 (with crossing)
- Examples: 34 + 28, 67 - 15

#### Level 4: Three-digit operands
- Addition: First operand 100-999; second operand 1-999, with crossing of the next ten boundary
- Subtraction: First operand 100-999; second operand 1-999, smaller than the first operand and satisfying the existing ten-boundary crossing rules
- Operands have up to three digits; addition results may have four digits, up to 1998
- Examples: 234 + 67, 110 + 235, 100 + 120, 345 - 235
- Levels 1-3 retain their existing ranges

### 5. User Interface Requirements

#### 5.1 Interactive Number Bond Widget
- **Number Selection Grid**: Select values required by the original, round-chunk, and place-value methods; required options must not be removed by a fixed option limit
- **Curated Suggestions**: The grid guarantees the documented teaching examples but does not enumerate every partition accepted by the validator
- **Number-Bond Diagram**: Show the second operand in a centered top whole circle, with two descending connector lines to two editable answer circles below
- **Part Fields**: Start with two lower answer circles; additional circles appear only through automatic canonical place-value extension, with no manual Add Part or Remove Part controls; permit selecting the same value more than once
- **Automatic Checking**: Check a filled answer after 700 ms without further input; no Check Answer button is required
- **Top Equation Answer**: Replace `?` with the calculated result immediately after a correct bond is checked; retain the existing worked steps and require no separate final-answer input
- **Part Number Picker**: Tapping any editable part circle opens a localized number picker with the same available choices as the existing selection grid; the grid remains available
- **Incomplete Place Value**: When the filled parts form an incomplete canonical place-value split, automatically add the missing empty circle(s) without counting a failed attempt; for example, 235 with 200 + 30 gains a third circle for the child to choose 5
- **Other Multi-Part Methods**: The validator continues to accept supported multi-part decompositions when supplied; the UI does not provide manual field controls for arbitrary multi-part splits
- **Visual Feedback**: Green for correct, orange for try again
- **Clear Button**: Clear the selected values and restore two empty answer circles, allowing a different two-part split after automatic place-value extension

#### 5.2 Attempt Management
- **3 Attempts Maximum**: Allow up to 3 wrong attempts
- **Automatic Feedback**: Show success/failure after a filled answer remains unchanged for 700 ms
- **Try Again Message**: Clear guidance with helpful hints
- **Explanation Display**: Show the child's actual selected parts and order after success; show the corrected solution matching the attempted method after 3 failures
- **Attempt Counting**: Count each checked entry once; edits, clear, automatic field changes, and opening a picker cancel pending checks; blank fields and incomplete canonical place-value splits do not consume an attempt
- **Retry Identity**: Selecting the same value or reopening/canceling a picker does not spend another attempt on an already checked entry; clearing and re-entering the same wrong answer counts as a new retry
- **Method-Aware Feedback**: Retry hints and final solutions follow the latest submitted method, retained through clear/refresh and reset for a new problem or explicit challenge retry
- **Single Reward**: Repeated submission must not award or record the same success more than once

#### 5.3 Success/Failure Flow
- **Success**: Reveal the result in the top equation and show the existing explanation → Next Challenge button
- **Answer State**: Keep the revealed result through save failures, saving retries and recovery of a correct pending completion. A new problem or explicit learning retry resets the equation to `?`; retrying a save preserves the completed answer
- **Unsolved Equation**: Failed attempts, terminal failure explanations and opening a history explanation leave `?` in the top equation until the child completes a correct bond
- **Failure**: Show try again message → Clear circles → Retry
- **3 Failures**: Show explanation → Next Challenge button

#### 5.4 Challenge Layout and Accessibility
- **Full Challenge Layout**: Keep the full page, its existing styles, expanded cards and original branching number-bond diagram
- **Section Order**: Place the question, number-bond circles, number choices, feedback and challenge actions first; place the child's name/profile and rewards/progress cards below the challenge interaction
- **Vertical Scrolling**: Allow the full challenge page to scroll so all sections, number choices, explanations and Next/Retry controls remain accessible
- **Diagram Geometry**: Keep the whole circle above its connected answer circles, including fields created by automatic place-value extension; lower circles may scroll horizontally if needed
- **Latest Layout Decision**: The user retained the previous full layout and requested the challenge interaction at the top; the earlier compact no-scroll workspace is no longer the active-page requirement
- **Circle Picker**: Keep the localized picker for editable answer circles and the existing number grid
- **Touch Targets**: Number and circle controls remain at least 44 logical pixels
- **Accessibility**: Label each part by its position and current value, expose selected/enabled states, and provide translated action labels
- **Responsive Verification**: Cover small portrait and landscape viewports, safe areas, English/Spanish/French and larger text, using scrolling to reach content without overflow

### 6. Performance Analytics

#### 6.1 Adaptive Engine Rules
- **Level Up**: ≥80% accuracy over the last 5 completed normal challenges at the current level
- **Stay Same**: 60-79% accuracy over those 5 challenges
- **Level Down**: <60% accuracy over those 5 challenges, with a minimum of Level 1
- **Fresh Level Evidence**: Require 5 outcomes at a newly reached level; easier review challenges do not advance or lower the normal level
- **Persistence**: Save the current level per child across app opens; evaluate each newly recorded normal outcome once, so repeated screen loads cannot change the level again
- **Review Injection**: After 2 consecutive incorrect answers
- **Regular Review**: After every 4 recorded challenge outcomes, when a suitable past mistake exists
- **Review Content**: Preserve the mistaken operation and use a level below the child's normal level when possible; a Level 1 review remains at Level 1
- **Operation Preference**: Apply the saved addition/subtraction/both preference to new challenges and review selection

#### 6.2 Data Tracking
- Problem type, numbers used, correctness, measured elapsed time, actual attempt count, hints used, and chosen decomposition method
- Store in local storage (SharedPreferences)
- Analyze every 20 unique recorded challenge outcomes per child for insights, using up to 100 recent outcomes from the last 7 days
- Deduplicate repeated terminal callbacks by event identity; retain separate outcomes for a failed challenge and its successful retry, even when they occur within a minute
- Preserve cumulative profile/reward totals independently from capped recent history; resetting one child's progress must preserve other children's data
- Generate motivational messages based on improvement

#### 6.3 Planned Learning Features
- A dedicated practice mode and multiple-profile chooser are planned; the current home screen opens the adaptive challenge and active profile
- Favorite numbers can be saved and edited; weighting generated adaptive challenges toward those values is planned

### 7. Technical Architecture

#### 7.1 Decoupled Services
```dart
// Problem Generation
CentralProblemGenerator.generateProblem(
  action: 'addition' | 'subtraction',
  level: 1-4
)

// Answer Validation  
AnswerValidator.validateAnswer(
  number1: int,
  number2: int, 
  action: string,
  userPart1: int,
  userPart2: int
) → ValidationResult(success: bool, message: string, proposedSolution: string)

// Flexible decomposition: extend validation to a list of selected parts
// while retaining the two-part entry point for existing callers.
// The result should include the detected method, corrected parts, and worked steps.
```

#### 7.2 Data Models
- **KidProfile**: Birth year, calculated age (legacy saved-age fallback), avatar, language, favorite numbers
- **AdaptiveChallenge**: Problem data, level, bond steps, motivational messages
- **ProblemAttempt**: Attempt history with detailed metrics
- **ValidationResult**: Success status with explanations

#### 7.3 State Management
- **Riverpod**: For profile and app state management
- **Local Storage**: SharedPreferences for persistence
- **Navigation**: GoRouter for screen navigation

### 8. Validation Rules

#### 8.1 Problem Generation Validation
- Both addition and subtraction, including generated reviews, exclude second operands exactly 10, 100 and 1000; apply the same rule to any generation fallback
- Standard subtraction problems must cross the ten boundary
- Standard subtraction generation excludes first operands ending in 0; retain the documented Level 1 exceptions 20 - 8 and 20 - 9
- All addition problems must cross next 10
- Suggested breakdowns use positive parts; legacy valid answers containing zero remain accepted under Section 8.2

#### 8.2 User Answer Validation
- **Generation Scope**: The excluded-second-operand rule does not change validation of an existing or supplied problem; the following decomposition rules continue to apply
- **Mathematical Correctness**: At least two nonnegative integer parts whose sum equals the second number
- **Addition**: Accept every decomposition satisfying mathematical correctness
- **Subtraction**: Accept valid existing two-part strategies or the new round-chunk rule: at least one positive multiple of 10 and at most one non-round remainder, in any order
- **Consistent Teaching**: Validation, retry hints, and worked solutions use the same detected method and preserve the original first operand
- **Incorrect Attempt**: Detect the attempted method without accepting an incorrect sum; explain a corrected decomposition
- **Regression Compatibility**: Preserve existing valid zero-containing answers; suggested decompositions use positive parts when possible

### 9. User Experience Requirements

#### 9.1 Responsive Design
- Support multiple screen sizes
- Prevent button overflow errors
- Consistent spacing and layout

#### 9.2 Multilingual Support
- Support multiple languages through LanguageService
- Localized feedback messages and instructions

#### 9.3 Motivational Elements
- Star rewards for correct answers
- Progress tracking and celebration
- Encouraging messages for improvement
- Visual feedback with animations

### 10. Quality Assurance

#### 10.1 Problem Generation Testing
- Verify no invalid problems are generated
- Test edge cases (numbers ending in 0, 9, etc.)
- Ensure standard problems follow crossing rules and the documented Level 1 exceptions remain solvable

#### 10.2 Validation Testing
- Test all valid user inputs are accepted
- Test invalid inputs are rejected with helpful feedback
- Verify attempt counting works correctly
- Verify automatic checking waits 700 ms, cancels on edits/picker/part changes/new problem, and does not repeat rewards or failed-attempt counts
- Verify the default whole circle sits above two lower answer circles, connector endpoints align with the lower circles, and automatically created place-value fields retain their branches
- Verify the question, diagram, number choices and challenge actions precede the profile and rewards/progress cards, with all sections accessible through vertical scrolling
- Verify circle pickers and the existing grid select the same values, and incomplete canonical place-value entry adds empty fields without failure
- Verify birth-year profiles recalculate age on later opens/resume and January 1; legacy profiles retain saved age until birth year is supplied
- Verify future birth years are rejected and profile/progress edits preserve the birth year

#### 10.3 Performance Testing
- Ensure smooth animations and interactions
- Test with large datasets of problem attempts
- Verify memory usage and app responsiveness

## Implementation Notes

### Critical Business Rules
1. **Flexible strategies**: Preserve existing valid answers and accept the agreed round-chunk/place-value decompositions in any order
2. **Crossing generation**: Standard problems cross ten boundaries; preserve the documented solvable Level 1 exceptions
3. **Mathematical accuracy**: All breakdowns must be mathematically correct
4. **User experience**: Clear feedback, helpful hints that match the attempted method, encouraging progression

### Architecture Principles
1. **Single Responsibility**: Each service handles one concern
2. **Decoupled Design**: UI separate from business logic
3. **Testable Components**: All logic can be unit tested
4. **Clear Data Flow**: Predictable state management
5. **Maintainable Code**: Well-documented, organized structure

This document represents the complete requirements based on our development journey and user feedback.


