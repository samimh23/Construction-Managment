# Contributing to Construction Management System

Thank you for your interest in contributing to the Construction Management System! 🎉

## 🤝 How to Contribute

We welcome contributions from the community. Whether it's:
- 🐛 Bug fixes
- ✨ New features
- 📝 Documentation improvements
- 🎨 UI/UX enhancements
- ⚡ Performance optimizations

## 📋 Getting Started

1. **Fork the repository**
   - Click the "Fork" button at the top right of the repository page

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR-USERNAME/Construction-Managment.git
   cd Construction-Managment
   ```

3. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/samimh23/Construction-Managment.git
   ```

4. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

## 💻 Development Workflow

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Make your changes**
   - Write clean, readable code
   - Follow the existing code style
   - Add comments for complex logic
   - Update documentation if needed

3. **Test your changes**
   ```bash
   # Run the app
   flutter run
   
   # Run tests (if available)
   flutter test
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add awesome feature"
   ```
   
   **Commit Message Format:**
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation changes
   - `style:` - Code style changes (formatting, etc.)
   - `refactor:` - Code refactoring
   - `test:` - Adding or updating tests
   - `chore:` - Maintenance tasks

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Open a Pull Request**
   - Go to the original repository
   - Click "New Pull Request"
   - Select your fork and branch
   - Fill in the PR template with details

## 📝 Pull Request Guidelines

### Before Submitting
- [ ] Code follows the project's style guidelines
- [ ] Self-review of your own code
- [ ] Commented code in hard-to-understand areas
- [ ] Updated documentation if needed
- [ ] No new warnings or errors
- [ ] Tested on both Android and iOS (if possible)

### PR Description Should Include
- **What**: Brief description of changes
- **Why**: Reason for the changes
- **How**: Implementation approach (if complex)
- **Screenshots**: For UI changes
- **Related Issues**: Link to related issues

### Example PR Title
```
feat: Add dark mode support to dashboard
fix: Resolve attendance sync issue on poor network
docs: Update installation instructions in README
```

## 🎨 Code Style Guidelines

### Dart/Flutter
- Use `dartfmt` for formatting: `flutter format .`
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable and function names
- Keep functions small and focused
- Add dartdoc comments for public APIs

### File Organization
```dart
// 1. Imports (grouped by type)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';

// 2. Class declaration
class MyWidget extends StatefulWidget {
  // 3. Constants
  static const String routeName = '/my-widget';
  
  // 4. Properties
  final String title;
  
  // 5. Constructor
  const MyWidget({Key? key, required this.title}) : super(key: key);
  
  // 6. Methods
  @override
  State<MyWidget> createState() => _MyWidgetState();
}
```

### Naming Conventions
- **Classes**: `PascalCase` (e.g., `UserProfile`)
- **Files**: `snake_case` (e.g., `user_profile.dart`)
- **Variables/Functions**: `camelCase` (e.g., `userName`, `fetchUserData()`)
- **Constants**: `camelCase` (e.g., `maxRetries`)
- **Private members**: `_leadingUnderscore` (e.g., `_privateMethod()`)

## 🐛 Reporting Bugs

### Before Reporting
- Check if the bug has already been reported
- Try to reproduce the issue
- Gather relevant information

### Bug Report Should Include
- **Title**: Clear, concise description
- **Description**: What happened vs. what should happen
- **Steps to Reproduce**: 
  1. Go to '...'
  2. Click on '....'
  3. See error
- **Expected Behavior**: What you expected
- **Actual Behavior**: What actually happened
- **Screenshots**: If applicable
- **Environment**:
  - Flutter version: `flutter --version`
  - Device: (e.g., Android 12, iOS 15)
  - App version

## 💡 Suggesting Features

We love new ideas! Before suggesting:
- Check if it already exists or is planned
- Consider if it fits the project scope
- Think about implementation approach

### Feature Request Should Include
- **Problem**: What problem does this solve?
- **Solution**: Proposed solution
- **Alternatives**: Other approaches considered
- **Additional Context**: Screenshots, mockups, examples

## 📦 Project Structure Guidelines

When adding new features:
- Place authentication-related code in `lib/auth/`
- Place manager features in `lib/Manger/`
- Place worker features in `lib/Worker/`
- Place shared utilities in `lib/core/`
- Follow the existing folder structure pattern

## ✅ Code Review Process

1. Maintainer reviews your PR
2. Feedback or change requests may be provided
3. Address feedback by pushing new commits
4. Once approved, your PR will be merged!

## 🙏 Code of Conduct

- Be respectful and constructive
- Welcome newcomers
- Focus on what's best for the community
- Show empathy towards others

## ❓ Questions?

- Open a [Discussion](https://github.com/samimh23/Construction-Managment/discussions)
- Reach out via email
- Ask in your PR/Issue

## 🎯 Good First Issues

Look for issues labeled:
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention needed
- `documentation` - Documentation improvements

---

Thank you for contributing to Construction Management System! 🚀

Your efforts help make this project better for everyone.
