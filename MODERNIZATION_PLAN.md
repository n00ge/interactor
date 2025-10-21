# Interactor Gem Modernization Plan

## Overview
This plan details the step-by-step modernization of the Interactor gem to align with current Ruby best practices and prepare for future Ruby versions.

---

## Phase 1: Critical Fixes (Breaking Changes Prevention)

### 1.1 Replace OpenStruct with Custom Implementation
**Priority:** CRITICAL
**Files:** `lib/interactor/context.rb`
**Estimated Effort:** 2-3 hours

**Current Code:**
```ruby
class Context < OpenStruct
```

**Implementation Steps:**
1. Create new `Context` class not inheriting from OpenStruct
2. Implement `initialize` to accept hash argument
3. Add `method_missing` for dynamic getter/setter support
4. Add `respond_to_missing?` for proper method introspection
5. Implement `to_h` or `to_hash` for hash conversion
6. Add `inspect` method for debugging output
7. Ensure all existing tests pass
8. Add performance benchmarks to verify improvement

**Testing:**
- Run full test suite
- Add specific tests for dynamic attribute access
- Test edge cases: nil values, symbol vs string keys
- Performance test vs OpenStruct baseline

---

### 1.2 Update Gemspec File Listing
**Priority:** CRITICAL
**Files:** `interactor.gemspec`
**Estimated Effort:** 15 minutes

**Changes:**
```ruby
# Remove:
spec.files = `git ls-files`.split($/)
spec.test_files = spec.files.grep(/^spec/)

# Replace with:
spec.files = Dir.glob(%w[
  lib/**/*.rb
  LICENSE.txt
  README.md
  CHANGELOG.md
  CONTRIBUTING.md
]).reject { |f| File.directory?(f) }
```

**Testing:**
- Build gem locally: `gem build interactor.gemspec`
- Verify file list: `gem spec interactor-3.1.0.gem files`
- Ensure no extra files included

---

### 1.3 Migrate from Travis CI to GitHub Actions
**Priority:** CRITICAL
**Files:** `.github/workflows/ci.yml` (new), `.travis.yml` (remove)
**Estimated Effort:** 1-2 hours

**Implementation:**
1. Create `.github/workflows/` directory
2. Create `ci.yml` workflow file
3. Configure matrix for Ruby versions: 2.7, 3.0, 3.1, 3.2, 3.3, 3.4, ruby-head
4. Set up RSpec test execution
5. Configure code coverage reporting
6. Test workflow on a branch
7. Remove `.travis.yml` after verification
8. Update README badges

**Workflow Structure:**
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    strategy:
      matrix:
        ruby: ['2.7', '3.0', '3.1', '3.2', '3.3', '3.4', 'head']
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ matrix.ruby }}
          bundler-cache: true
      - run: bundle exec rspec
```

---

## Phase 2: High Priority Updates

### 2.1 Add Ruby Version Requirement
**Priority:** HIGH
**Files:** `interactor.gemspec`
**Estimated Effort:** 10 minutes

**Changes:**
```ruby
spec.required_ruby_version = ">= 2.7.0"
```

**Rationale:**
- Ruby 2.7 introduced keyword argument separation (ready for Ruby 3)
- All earlier versions are EOL
- Allows use of modern syntax

---

### 2.2 Update Development Dependencies
**Priority:** HIGH
**Files:** `interactor.gemspec`, `Gemfile`
**Estimated Effort:** 30 minutes

**Changes:**
```ruby
# In gemspec:
spec.add_development_dependency "bundler", ">= 2.0"
spec.add_development_dependency "rake", ">= 13.0"
spec.add_development_dependency "rspec", "~> 3.12"

# In Gemfile:
group :test do
  gem "simplecov", require: false
  gem "simplecov-lcov", require: false
end

group :development do
  gem "standard", "~> 1.0"
  gem "rubocop", "~> 1.50"
  gem "rubocop-rspec", "~> 2.20"
end
```

**Testing:**
- Run `bundle update`
- Verify all specs pass
- Check for deprecation warnings

---

### 2.3 Add Frozen String Literals
**Priority:** HIGH
**Files:** All `.rb` files
**Estimated Effort:** 20 minutes

**Implementation:**
1. Add `# frozen_string_literal: true` as first line to:
   - `lib/interactor.rb`
   - `lib/interactor/context.rb`
   - `lib/interactor/error.rb`
   - `lib/interactor/hooks.rb`
   - `lib/interactor/organizer.rb`
   - All spec files
2. Remove `# encoding: utf-8` from `interactor.gemspec`
3. Run tests to catch any string mutation issues
4. Fix any failures (unlikely given the codebase structure)

**Automated Approach:**
```bash
# Add frozen string literal to all Ruby files
find lib spec -name "*.rb" -type f -exec sed -i '1i# frozen_string_literal: true\n' {} \;
```

---

### 2.4 Replace CodeClimate Test Reporter
**Priority:** HIGH
**Files:** `spec/spec_helper.rb`, `Gemfile`, GitHub Actions
**Estimated Effort:** 45 minutes

**Implementation:**
1. Remove CodeClimate test reporter
2. Add SimpleCov configuration
3. Configure SimpleCov for GitHub Actions
4. Add coverage badge to README

**New `spec/spec_helper.rb`:**
```ruby
# frozen_string_literal: true

if ENV["COVERAGE"]
  require "simplecov"

  SimpleCov.start do
    add_filter "/spec/"
    enable_coverage :branch
    minimum_coverage line: 100, branch: 95
  end
end

require "interactor"

Dir[File.expand_path("../support/*.rb", __FILE__)].each { |f| require f }
```

---

### 2.5 Clean Up Gemspec
**Priority:** HIGH
**Files:** `interactor.gemspec`
**Estimated Effort:** 20 minutes

**Complete Updated Gemspec:**
```ruby
# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name    = "interactor"
  spec.version = "3.2.0" # or 4.0.0 if breaking changes
  spec.authors = ["Collective Idea"]
  spec.email   = ["info@collectiveidea.com"]

  spec.summary     = "Simple interactor implementation"
  spec.description = "Interactor provides a common interface for performing complex user interactions."
  spec.homepage    = "https://github.com/collectiveidea/interactor"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata = {
    "bug_tracker_uri"       => "https://github.com/collectiveidea/interactor/issues",
    "changelog_uri"         => "https://github.com/collectiveidea/interactor/blob/master/CHANGELOG.md",
    "source_code_uri"       => "https://github.com/collectiveidea/interactor",
    "documentation_uri"     => "https://rubydoc.info/gems/interactor",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.glob(%w[
    lib/**/*.rb
    LICENSE.txt
    README.md
    CHANGELOG.md
  ]).reject { |f| File.directory?(f) }

  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 2.0"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
end
```

---

## Phase 3: Recommended Improvements

### 3.1 Add RuboCop Configuration
**Priority:** MEDIUM
**Files:** `.rubocop.yml` (new), `Rakefile`
**Estimated Effort:** 1-2 hours

**Implementation:**
1. Create `.rubocop.yml` configuration
2. Run RuboCop and fix auto-correctable issues
3. Review and address remaining issues
4. Add RuboCop to Rake tasks
5. Add to CI workflow

**Sample `.rubocop.yml`:**
```yaml
require:
  - rubocop-rspec

AllCops:
  TargetRubyVersion: 2.7
  NewCops: enable
  SuggestExtensions: false
  Exclude:
    - 'vendor/**/*'

Style/Documentation:
  Enabled: false # Already using TomDoc

Metrics/BlockLength:
  Exclude:
    - 'spec/**/*'

Layout/LineLength:
  Max: 120
```

---

### 3.2 Add Dependabot Configuration
**Priority:** MEDIUM
**Files:** `.github/dependabot.yml` (new)
**Estimated Effort:** 15 minutes

**Configuration:**
```yaml
version: 2
updates:
  - package-ecosystem: "bundler"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

---

### 3.3 Update README Badges
**Priority:** MEDIUM
**Files:** `README.md`
**Estimated Effort:** 20 minutes

**Remove:**
- Travis CI badge
- Gemnasium badge
- CodeClimate coverage badge

**Add/Update:**
```markdown
[![Gem Version](https://img.shields.io/gem/v/interactor.svg)](https://rubygems.org/gems/interactor)
[![CI Status](https://github.com/collectiveidea/interactor/workflows/CI/badge.svg)](https://github.com/collectiveidea/interactor/actions)
[![Code Coverage](https://img.shields.io/badge/coverage-100%25-success)](https://github.com/collectiveidea/interactor)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)
```

---

### 3.4 Add Security Scanning
**Priority:** MEDIUM
**Files:** `.github/workflows/security.yml` (new)
**Estimated Effort:** 30 minutes

**Implementation:**
Create workflow for:
- Bundler Audit (check for vulnerable dependencies)
- Brakeman (static security analysis - if applicable)

```yaml
name: Security
on:
  push:
    branches: [master]
  pull_request:
  schedule:
    - cron: '0 0 * * 1' # Weekly on Monday

jobs:
  bundler-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true
      - name: Install bundler-audit
        run: gem install bundler-audit
      - name: Run bundler-audit
        run: bundle-audit check --update
```

---

## Phase 4: Modern Ruby Features (Optional)

### 4.1 Add RBS Type Signatures
**Priority:** LOW
**Files:** `sig/**/*.rbs` (new)
**Estimated Effort:** 3-4 hours

**Implementation:**
1. Create `sig/` directory
2. Add type signatures for public API
3. Add steep or type_check gem
4. Run type checker in CI

**Example Structure:**
```
sig/
  interactor.rbs
  interactor/
    context.rbs
    organizer.rbs
    hooks.rbs
```

---

### 4.2 Leverage Modern Ruby Syntax
**Priority:** LOW
**Files:** Various
**Estimated Effort:** 2-3 hours

**Opportunities:**
- Endless method definitions for simple one-liners
- Hash shorthand syntax (Ruby 3.1+) where applicable
- Pattern matching for context validation (Ruby 3.0+)
- Numbered parameters in simple blocks

**Example:**
```ruby
# Before
def success?
  !failure?
end

# After (if method is truly this simple)
def success? = !failure?
```

**Note:** Must maintain Ruby 2.7 compatibility if targeting that version.

---

## Phase 5: Testing & Documentation

### 5.1 Enhance Test Coverage
**Priority:** MEDIUM
**Files:** `spec/**/*_spec.rb`
**Estimated Effort:** 2-3 hours

**Tasks:**
1. Ensure 100% line and branch coverage
2. Add edge case tests
3. Add performance benchmarks
4. Test Ruby 3.4 compatibility

---

### 5.2 Update Documentation
**Priority:** MEDIUM
**Files:** `README.md`, inline docs
**Estimated Effort:** 1-2 hours

**Tasks:**
1. Update installation instructions
2. Add Ruby version compatibility matrix
3. Update contributing guidelines
4. Add security policy
5. Update code examples to modern syntax

---

### 5.3 Update CHANGELOG
**Priority:** HIGH
**Files:** `CHANGELOG.md`
**Estimated Effort:** 30 minutes

**Document all changes:**
```markdown
## 4.0.0 / 2025-XX-XX

### Breaking Changes
* Require Ruby >= 2.7.0
* Replace OpenStruct with custom Context implementation (performance improvement)

### Enhancements
* Add frozen string literal comments to all files
* Migrate CI from Travis to GitHub Actions
* Add RuboCop for code quality
* Add Dependabot for dependency updates
* Add SimpleCov for test coverage
* Add comprehensive gemspec metadata

### Bug Fixes
* None

### Maintenance
* Update all development dependencies
* Remove deprecated test_files gemspec attribute
* Remove unnecessary encoding comments
```

---

## Implementation Timeline

### Week 1: Critical Fixes
- Day 1-2: OpenStruct replacement + comprehensive testing
- Day 3: Gemspec updates, frozen string literals
- Day 4-5: GitHub Actions migration, CI testing

### Week 2: High Priority Updates
- Day 1: Dependencies update, test suite verification
- Day 2: SimpleCov integration, coverage analysis
- Day 3-4: RuboCop setup and fixes
- Day 5: Documentation updates

### Week 3: Polish & Release
- Day 1-2: Dependabot, security scanning
- Day 3: Final testing across all Ruby versions
- Day 4: CHANGELOG and version bump
- Day 5: Release preparation and gem publication

---

## Testing Strategy

### Pre-Release Checklist
- [ ] All specs pass on Ruby 2.7, 3.0, 3.1, 3.2, 3.3, 3.4
- [ ] 100% test coverage maintained
- [ ] No RuboCop offenses
- [ ] Gem builds successfully
- [ ] Performance benchmarks show improvement (OpenStruct replacement)
- [ ] Documentation is up to date
- [ ] CHANGELOG is complete
- [ ] Version is bumped appropriately

### Performance Benchmarks
Create benchmarks to verify OpenStruct replacement improves performance:
```ruby
require 'benchmark/ips'

Benchmark.ips do |x|
  x.report("context creation") { Interactor::Context.new(foo: "bar") }
  x.report("context access") { context.foo }
  x.report("context mutation") { context.bar = "baz" }
  x.compare!
end
```

---

## Risk Assessment

### High Risk
- **OpenStruct replacement:** Could break user code if not 100% compatible
  - Mitigation: Extensive testing, beta release

### Medium Risk
- **Ruby version requirement:** May break deployments on old Ruby
  - Mitigation: Semantic versioning (4.0.0), clear communication

### Low Risk
- **CI migration:** Internal only
- **Linting/formatting:** Auto-fixable
- **Documentation:** No code impact

---

## Rollback Plan

If issues arise post-release:
1. Immediately yank the gem version: `gem yank interactor -v X.Y.Z`
2. Investigate and fix issues
3. Release patch version with fixes
4. Document issues in CHANGELOG

---

## Communication Plan

1. **Before Work Starts:** Open GitHub issue discussing modernization plans
2. **During Development:** Regular updates on progress
3. **Pre-Release:** Beta gem for community testing
4. **Release:** Announcement with migration guide
5. **Post-Release:** Monitor issues, respond promptly

---

## Version Numbering

Given the changes, recommend: **4.0.0**

**Rationale:**
- Breaking: Minimum Ruby version requirement (2.7+)
- Breaking: OpenStruct removal (potential edge cases)
- Major: Significant modernization effort

Alternative: **3.2.0** if maintaining backward compatibility is critical
