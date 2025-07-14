# Contributing to Random MTG Card Display

Thank you for your interest in contributing! This project uses automated release management, so please follow these guidelines to ensure smooth releases.

## Development Workflow

1. **Fork & Clone**
   ```bash
   git clone <your-fork-url>
   cd random-mtg-card
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   ```

3. **Create Feature Branch**
   ```bash
   git checkout -b feat/your-feature-name
   ```

4. **Develop & Test**
   ```bash
   # Run tests
   flutter test
   flutter test integration_test/
   
   # Check code quality
   flutter analyze
   
   # Test builds
   ./scripts/build_universal.sh debug
   ```

5. **Commit with Conventional Messages**
   ```bash
   # Examples:
   git commit -m "feat: add new card filter option"
   git commit -m "fix: resolve macOS network permission issue"
   git commit -m "docs: update installation instructions"
   ```

6. **Push & Create PR**
   ```bash
   git push origin feat/your-feature-name
   ```

## Commit Message Guidelines

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automated release management.

### Format
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types
- `feat`: New feature (→ minor version bump)
- `fix`: Bug fix (→ patch version bump)
- `docs`: Documentation changes
- `style`: Formatting, missing semicolons, etc.
- `refactor`: Code change that neither fixes bug nor adds feature
- `perf`: Performance improvement (→ patch version bump)
- `test`: Adding or correcting tests
- `build`: Build system or dependency changes
- `ci`: CI configuration changes
- `chore`: Maintenance tasks

### Scopes (Optional)
- `ui`: User interface changes
- `api`: API/service layer changes
- `config`: Configuration changes
- `build`: Build system changes
- `test`: Testing-related changes

### Examples
```bash
# Feature additions
feat(ui): add dark mode toggle to settings
feat(api): implement advanced card filtering
feat: add favorites export functionality

# Bug fixes
fix(ui): resolve card image aspect ratio on mobile
fix(config): handle corrupted settings gracefully
fix: prevent duplicate cards in favorites

# Performance improvements
perf(api): optimize card caching mechanism
perf: reduce memory usage in card history

# Documentation
docs: add cross-platform setup guide
docs(api): document filter configuration options

# Breaking changes (major version bump)
feat!: redesign settings configuration format

BREAKING CHANGE: Settings now use JSON schema v2
```

## Code Standards

### Flutter/Dart
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter analyze` to check code quality
- Format code with `dart format .`
- Add tests for new features
- Update documentation for API changes

### Testing Requirements
- **Unit tests**: Test business logic and services
- **Widget tests**: Test UI components in isolation  
- **Integration tests**: Test complete user workflows
- Maintain >90% code coverage
- All tests must pass before merging

### File Organization
```
lib/
├── models/          # Data models and JSON serialization
├── services/        # API services and business logic
├── providers/       # State management
├── screens/         # Full-screen UI components
├── widgets/         # Reusable UI components
└── main.dart        # App entry point

test/
├── unit/           # Unit tests
├── widget/         # Widget tests
└── integration/    # Integration tests
```

## Release Process

Releases are fully automated via [Release Please](https://github.com/googleapis/release-please):

1. **Make Changes**: Create PR with conventional commits
2. **Review & Merge**: Maintainers review and merge to `main`
3. **Release PR**: Release Please automatically creates release PR
4. **Publish**: Merging release PR triggers:
   - Version bump in `pubspec.yaml`
   - `CHANGELOG.md` update
   - Git tag creation
   - Cross-platform build artifacts
   - GitHub release publication

## Getting Help

- **Issues**: Use GitHub Issues for bugs and feature requests
- **Discussions**: Use GitHub Discussions for questions
- **Discord**: Join our community Discord for real-time help

## Recognition

Contributors are automatically credited in release notes based on their commit messages. Thank you for helping make this project better!

## License

By contributing, you agree that your contributions will be licensed under the MIT License. 