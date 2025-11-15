# Contributing to ServiceActor

ServiceActor is open source and contributions from the community are encouraged!
No contribution is too small.

Please consider:

* adding a feature
* squashing a bug
* writing [documentation](http://tomdoc.org)
* reporting an issue
* fixing a typo
* correcting [style](https://github.com/rubocop/ruby-style-guide)

## How do I contribute?

For the best chance of having your changes merged, please:

1. [Fork](https://github.com/n00ge/service-actor/fork) the project.
2. [Write](http://en.wikipedia.org/wiki/Test-driven_development) a failing test.
3. [Commit](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html) changes that fix the tests.
4. [Submit](https://github.com/n00ge/service-actor/pulls) a pull request with *at least* one animated GIF.
5. Be patient.

If your proposed changes only affect documentation, include the following on a
new line in each of your commit messages:

```
[ci skip]
```

This will signal CI that running the test suite is not necessary for these changes.

## Bug Reports

If you are experiencing unexpected behavior and, after having read ServiceActor's
documentation, are convinced this behavior is a bug, please:

1. [Search](https://github.com/n00ge/service-actor/issues) existing issues.
2. Collect enough information to reproduce the issue:
  * ServiceActor version
  * Ruby version
  * Rails version (if applicable)
  * Specific setup conditions
  * Description of expected behavior
  * Description of actual behavior
3. [Submit](https://github.com/n00ge/service-actor/issues/new) an issue.
4. Be patient.

## Development

### Setup

```bash
git clone https://github.com/n00ge/service-actor.git
cd service-actor
bundle install
```

### Running Tests

```bash
bundle exec rspec
```

### Code Style

Follow the [Ruby Style Guide](https://github.com/rubocop/ruby-style-guide).

## Acknowledgments

ServiceActor is a modernized fork of [collectiveidea/interactor](https://github.com/collectiveidea/interactor).
Special thanks to Collective Idea for their pioneering work on the interactor pattern in Ruby.
