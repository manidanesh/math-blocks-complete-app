# Math Blocks Complete App - Requirements Document

## Project Overview
An adaptive math learning app for children that teaches addition and subtraction using the Number Bond strategy. The app dynamically adjusts difficulty based on performance and provides engaging, educational experiences.

## Core Features

### 1. User Profile Management
- **Profile Creation**: Age selection (4-12), avatar selection, language selection
- **Multiple Profiles**: Support for multiple children per device
- **Profile History**: Track performance, failed attempts, and progress over time
- **Insights Display**: Show learning patterns and performance analytics

### 2. Adaptive Challenge System
- **Dynamic Difficulty**: Adjusts problem difficulty based on recent performance
- **Performance Tracking**: Monitors accuracy, time taken, hint usage
- **Level Progression**: 4 difficulty levels with automatic advancement/regression
- **Review Problems**: Injects easier problems when struggling

### 3. Number Bond Strategy Teaching

#### 3.1 Problem Generation Rules
**Addition Problems:**
- Must "cross the next 10" (e.g., 47 + 6, not 45 + 3)
- Break second number to make ten first
- Example: 47 + 6 → 6 breaks into 3 + 3 → 47 + 3 + 3 = 50 + 3 = 53

**Subtraction Problems:**
- Must "cross the ten boundary" (e.g., 42 - 7, not 42 - 1)
- Break second number to reach next lower ten first
- Example: 42 - 7 → 7 breaks into 2 + 5 → 42 - 2 - 5 = 40 - 5 = 35

#### 3.2 Special Rules for Numbers Ending in 0
- For numbers like 30, 40, 50, etc.
- Must subtract more than 10 to cross ten boundary
- Example: 30 - 11 ✅ (crosses to 19), but 30 - 8 ❌ (stays in 20s)

#### 3.3 Order Requirements
- **First circle**: Must contain the ones digit of the first number
- **Second circle**: Contains the remaining part
- Example: 42 - 7 → First circle: 2, Second circle: 5

### 4. Difficulty Levels

#### Level 1: Single-digit addition
- Range: 1-9 + 1-9
- Must cross 10 (sum > 10)
- Example: 7 + 5 = 12

#### Level 2: 2-digit operations
- Addition: 10-99 + 1-9 (crossing next 10)
- Subtraction: 20-99 - 1-18 (crossing ten boundary)
- Examples: 47 + 6, 42 - 7

#### Level 3: 2-digit + 2-digit
- Range: 10-99 + 10-99 (with crossing)
- Range: 50-99 - 10-18 (with crossing)
- Examples: 34 + 28, 67 - 15

#### Level 4: Up to 3-digit
- Range: 100-999 + 1-99
- Range: 100-999 - 1-99
- Examples: 234 + 67, 345 - 78

### 5. User Interface Requirements

#### 5.1 Interactive Number Bond Widget
- **Number Selection Grid**: Tap numbers 0-9 to fill circles
- **Two Circles**: First circle (ones digit), Second circle (remainder)
- **Visual Feedback**: Green for correct, orange for try again
- **Clear Button**: Reset and try again functionality

#### 5.2 Attempt Management
- **3 Attempts Maximum**: Allow up to 3 wrong attempts
- **Immediate Feedback**: Show success/failure immediately
- **Try Again Message**: Clear guidance with helpful hints
- **Explanation Display**: Show solution after success or 3 failures

#### 5.3 Success/Failure Flow
- **Success**: Show explanation → Next Challenge button
- **Failure**: Show try again message → Clear circles → Retry
- **3 Failures**: Show explanation → Next Challenge button

### 6. Performance Analytics

#### 6.1 Adaptive Engine Rules
- **Level Up**: ≥80% accuracy over last 5 problems
- **Stay Same**: 60-79% accuracy
- **Level Down**: <60% accuracy
- **Review Injection**: After 2 consecutive incorrect answers
- **Regular Review**: Every 4 challenges from past mistakes

#### 6.2 Data Tracking
- Problem type, numbers used, correctness, time taken, hints used
- Store in local storage (SharedPreferences)
- Analyze every 20 problems for insights
- Generate motivational messages based on improvement

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
```

#### 7.2 Data Models
- **KidProfile**: Age, avatar, language, favorite numbers
- **AdaptiveChallenge**: Problem data, level, bond steps, motivational messages
- **ProblemAttempt**: Attempt history with detailed metrics
- **ValidationResult**: Success status with explanations

#### 7.3 State Management
- **Riverpod**: For profile and app state management
- **Local Storage**: SharedPreferences for persistence
- **Navigation**: GoRouter for screen navigation

### 8. Validation Rules

#### 8.1 Problem Generation Validation
- All subtraction problems must cross ten boundary
- Numbers ending in 0 require subtraction > 10
- All addition problems must cross next 10
- No trivial breakdowns (e.g., 9 → 9 + 0)

#### 8.2 User Answer Validation
- **Mathematical Correctness**: userPart1 + userPart2 = secondNumber
- **Order Correctness**: userPart1 = ones digit of firstNumber
- **Both conditions must be true for success**

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
- Ensure all problems follow crossing rules

#### 10.2 Validation Testing
- Test all valid user inputs are accepted
- Test invalid inputs are rejected with helpful feedback
- Verify attempt counting works correctly

#### 10.3 Performance Testing
- Ensure smooth animations and interactions
- Test with large datasets of problem attempts
- Verify memory usage and app responsiveness

## Implementation Notes

### Critical Business Rules
1. **Order is paramount**: First circle = ones digit, always
2. **Crossing is mandatory**: All problems must cross ten boundaries
3. **Mathematical accuracy**: All breakdowns must be mathematically correct
4. **User experience**: Clear feedback, helpful hints, encouraging progression

### Architecture Principles
1. **Single Responsibility**: Each service handles one concern
2. **Decoupled Design**: UI separate from business logic
3. **Testable Components**: All logic can be unit tested
4. **Clear Data Flow**: Predictable state management
5. **Maintainable Code**: Well-documented, organized structure

This document represents the complete requirements based on our development journey and user feedback.


