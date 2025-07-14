# Memory Bank: Release Please Setup and Usage

## Project Overview
**Random MTG Card Display** - A Flutter app for displaying random Magic: The Gathering cards with comprehensive filter system and favorites management.

## Release Please Configuration

### Core Setup
- **Package Name**: `random-mtg-card`
- **Release Type**: `dart` (Flutter/Dart project)
- **Version File**: `pubspec.yaml`
- **Current Version**: `0.0.0` (reset to bootstrap initial release)
- **Manifest File**: `.github/.release-please-manifest.json`
- **Config File**: `.github/release-please-config.json`

### Automated Release Workflow
**File**: `.github/workflows/release-please.yml`

**Trigger**: Push to `main` branch

**Action**: `googleapis/release-please-action@v4` (updated from deprecated `google-github-actions/release-please-action`)

**Permissions Required**:
- `contents: write` - Create releases and tags
- `pull-requests: write` - Create and update release PRs  
- `issues: write` - Create and manage labels (autorelease: pending, etc.)

**Two-Stage Process**:
1. **Release Please Job**: 
   - Creates/updates release PR with changelog
   - Manages version bumping based on conventional commits
   - Outputs `releases_created` and `tag_name` for downstream jobs

2. **Build Artifacts Job**: 
   - Runs only when new release is created
   - Cross-platform builds (Linux, macOS, Windows)
   - Attaches binary artifacts to GitHub release
   - Uses matrix strategy for parallel builds

### Cross-Platform Build Integration
**Build Scripts**:
- `./scripts/build_linux.sh` → `mtg-card-display-linux.tar.gz`
- `./scripts/build_macos.sh` → `mtg-card-display-macos.zip`
- `./scripts/build_windows.bat` → `mtg-card-display-windows.zip`

**Artifact Paths**:
- Linux: `build/linux/x64/release/bundle/`
- macOS: `build/macos/Build/Products/Release/random_mtg_card.app`
- Windows: `build/windows/x64/runner/Release/`

### Conventional Commit Configuration

**Version Bumping Rules**:
- `feat:` → **Minor version bump** (1.0.0 → 1.1.0)
- `fix:` → **Patch version bump** (1.0.0 → 1.0.1)
- `feat!:` or `BREAKING CHANGE:` → **Major version bump** (1.0.0 → 2.0.0)
- `perf:` → **Patch version bump** (performance improvements)

**Changelog Sections**:
- **Visible in changelog**: `feat`, `fix`, `perf`, `revert`, `docs`
- **Hidden from changelog**: `style`, `chore`, `refactor`, `test`, `build`, `ci`

**Configuration Options**:
- `bump-minor-pre-major: true` - Allows minor bumps before 1.0.0
- `bump-patch-for-minor-pre-major: true` - Allows patch bumps before 1.0.0

### Release Please Manifest Tracking
**File**: `.github/.release-please-manifest.json`
```json
{
  ".": "0.0.0"
}
```
- Tracks current version for the root package
- Updated automatically by Release Please
- Required for multi-package repositories
- **Note**: Reset to `0.0.0` to bootstrap initial release (was `1.0.0` but no corresponding git tag existed)

### Pubspec.yaml Version Management
**Extra Files Configuration**:
```json
"extra-files": [
  {
    "type": "yaml",
    "path": "pubspec.yaml",
    "jsonpath": "$.version"
  }
]
```
- Automatically updates `version:` field in pubspec.yaml
- Uses JSONPath to locate version string
- Maintains Flutter/Dart version format compatibility

## Usage Patterns

### Development Workflow
1. **Feature Development**: Create feature branch with conventional commits
2. **PR Creation**: Submit PR with conventional commit messages
3. **Review & Merge**: Maintainers merge to main branch
4. **Automated Release**: Release Please creates release PR automatically
5. **Release Publishing**: Merging release PR triggers build and publish

### Commit Message Examples
```bash
# Feature additions (minor version bump)
feat(ui): add dark mode toggle to settings
feat(api): implement advanced card filtering
feat: add favorites export functionality

# Bug fixes (patch version bump)
fix(ui): resolve card image aspect ratio on mobile
fix(config): handle corrupted settings gracefully
fix: prevent duplicate cards in favorites

# Performance improvements (patch version bump)
perf(api): optimize card caching mechanism
perf: reduce memory usage in card history

# Breaking changes (major version bump)
feat!: redesign settings configuration format
```

### Scoping Guidelines
- `ui`: User interface changes
- `api`: API/service layer changes
- `config`: Configuration changes
- `build`: Build system changes
- `test`: Testing-related changes

## Current Project State

### Version History
- **Bootstrap Stage**: Repository configured for automated releases
  - Release Please manifest reset to `0.0.0` 
  - Next release will be the initial version based on conventional commits
  - Features ready for initial release:
    - Cross-platform support (Windows, macOS, Linux)
    - Settings menu with filter configuration
    - Favorites system with search and sort
    - Navigation menu with animations
    - MTG card display with gesture controls
    - Filter system with Scryfall API integration
    - Comprehensive testing suite
    - Professional UI with dark theme

### Key Features Implemented
- **Settings Menu**: Searchable multi-select filters for sets, colors, types, rarity, formats
- **Favorites System**: Grid layout, search, sort, card details popup, batch operations
- **Navigation Menu**: Animated overlay with modern design
- **Filter System**: Real-time filtering with Scryfall API
- **Cross-Platform**: Native builds for all major platforms
- **Testing**: 90%+ code coverage with unit, widget, and integration tests

## CI/CD Integration

### Continuous Integration
**File**: `.github/workflows/ci.yml`
- Runs on PRs and pushes to main
- Testing: Unit, widget, and integration tests
- Code quality: Analyze and format checks
- Cross-platform build verification
- Prevents broken releases

### Quality Gates
- All tests must pass
- Code analysis must pass
- Format checks must pass
- Cross-platform builds must succeed
- Minimum 90% code coverage

## Best Practices

### For Contributors
1. **Always use conventional commits** for proper version bumping
2. **Include scope** when changes affect specific areas
3. **Write descriptive commit messages** for clear changelog entries
4. **Test thoroughly** before submitting PRs
5. **Update documentation** for API changes
6. **⚠️ ALWAYS run `dart format .` before committing** - CI fails if files are not properly formatted

### For Maintainers
1. **Review commit messages** during PR review
2. **Squash merge** to maintain clean commit history
3. **Verify CI passes** before merging
4. **Monitor release PR** for proper changelog generation
5. **Test releases** before final publication

## Troubleshooting

### Common Issues
- **Missing artifacts**: Check build script permissions and paths
- **Version conflicts**: Ensure manifest.json is updated
- **Changelog formatting**: Verify conventional commit format
- **Build failures**: Check platform-specific dependencies
- **Invalid previous_tag parameter**: Manifest version doesn't match existing git tags - reset manifest to `0.0.0` for new repos
- **⚠️ Formatting check failures**: Always run `dart format .` before committing - CI has strict formatting requirements
- **"GitHub Actions is not permitted to create or approve pull requests"**: Repository settings need to allow Actions to create PRs
  - Go to Settings → Actions → General → Workflow permissions
  - Enable "Allow GitHub Actions to create and approve pull requests"
- **"You do not have permission to create labels on this repository"**: Workflow needs `issues: write` permission
  - Add `issues: write` to the permissions section in the workflow file
- **"release-please failed: Invalid previous_tag parameter"**: Manifest version doesn't match existing git tags
  - Reset manifest to `0.0.0` for new repos, sync pubspec.yaml version
- **Code analysis failures in CI**: Missing provider methods, type mismatches, null safety issues
  - Add missing public methods to providers for testing
  - Fix nullable types and null-safety issues
  - Remove unused imports and clean up code quality issues
- **Flutter analysis issues (41 → 0)**: Comprehensive code quality improvements
  - Replace `print()` with `debugPrint()` for production-safe logging (30 issues)
  - Replace deprecated `withOpacity()` with `withValues(alpha:)` (8 issues)
  - Make private fields `final` where appropriate (2 issues)
  - Replace `Container` with `SizedBox` for whitespace (2 issues)
  - Use `const` for compile-time constants (1 issue)
  - Remove unused variables (1 issue)
  - Add proper imports for `debugPrint` from `flutter/foundation.dart`

### Debug Commands
```bash
# Check Release Please config
gh api repos/:owner/:repo/releases/latest

# Verify build scripts
chmod +x ./scripts/build_*.sh
./scripts/build_universal.sh debug

# Test conventional commits
git log --oneline --grep="feat\|fix\|perf"

# Fix formatting issues (run before committing)
dart format .

# Check if formatting is correct
dart format --output=none --set-exit-if-changed .
```

## Integration Benefits

### Automated Release Management
- **Zero-effort releases**: No manual version bumping or changelog maintenance
- **Consistent versioning**: Semantic versioning based on commit types
- **Cross-platform builds**: Automatic artifact generation for all platforms
- **Professional releases**: Consistent changelog format and GitHub releases

### Developer Experience
- **Clear contribution guidelines**: Conventional commits provide structure
- **Automated testing**: CI ensures quality before releases
- **Instant feedback**: Failed builds caught early in development
- **Documentation sync**: Changelog automatically reflects changes

### Project Maintenance
- **Release history**: Complete audit trail of all changes
- **Artifact management**: Binaries automatically attached to releases
- **Version tracking**: Manifest maintains current state
- **Quality assurance**: Multiple quality gates before release

This Release Please setup provides a complete, professional release management system that scales with the project while maintaining high quality standards and developer productivity. 