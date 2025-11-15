# Migrating from collectiveidea/interactor to ServiceActor

ServiceActor is a modernized fork of [collectiveidea/interactor](https://github.com/collectiveidea/interactor). This guide will help you migrate your existing interactor code to ServiceActor.

## Quick Migration

ServiceActor provides **backward compatibility aliases** for seamless migration. Your existing code should continue to work without changes:

```ruby
# This still works
class AuthenticateUser
  include Interactor  # Aliased to ServiceActor

  def call
    # Your existing code works as-is
  end
end

# Failure handling still works
rescue Interactor::Failure => e  # Aliased to ServiceActor::Failure

# Organizers still work
class PlaceOrder
  include Interactor::Organizer  # Aliased to ServiceActor::Organizer
end

# Contracts work too
class CreateUser
  include Interactor::Contracts  # Aliased to ServiceActor::Contracts
end
```

## Installation

1. **Update your Gemfile:**

```ruby
# Remove this
gem 'interactor', '~> 3.0'

# Add this
gem 'service-actor', '~> 1.0'
```

2. **Run bundle update:**

```bash
bundle install
```

3. **Test your application** - Everything should continue to work!

## Gradual Migration (Recommended)

While backward compatibility aliases are provided, we recommend gradually updating your code to use `ServiceActor` for clarity:

### Step 1: Update requires (if explicit)

```ruby
# Old
require 'interactor'

# New
require 'service_actor'
```

### Step 2: Update module includes

```ruby
# Old
class AuthenticateUser
  include Interactor
end

# New
class AuthenticateUser
  include ServiceActor
end
```

### Step 3: Update organizers

```ruby
# Old
class PlaceOrder
  include Interactor::Organizer
end

# New
class PlaceOrder
  include ServiceActor::Organizer
end
```

### Step 4: Update exception handling

```ruby
# Old
rescue Interactor::Failure => e

# New
rescue ServiceActor::Failure => e
```

### Step 5: Update directory structure (optional)

```
# Old
app/interactors/
  authenticate_user.rb
  place_order.rb

# New (recommended)
app/actors/
  authenticate_user.rb
  place_order.rb
```

## Breaking Changes from interactor 3.x

### Ruby Version Requirement

ServiceActor requires **Ruby 3.0.0 or higher**. If you're using an older Ruby version, you must upgrade first.

```ruby
# .ruby-version
3.0.0  # or higher
```

### OpenStruct Removed

The `Context` class no longer inherits from `OpenStruct` (which is deprecated in Ruby 3.2+). We use a custom implementation that maintains the same API.

**This change is backwards compatible** - your existing code should continue to work:

```ruby
# All of these still work exactly as before
context = ServiceActor::Context.new(foo: "bar")
context.foo          # => "bar"
context.baz = "qux"  # Dynamic setters still work
context[:foo]        # => "bar" (hash-like access still works)
```

### Dependency Updates

- Bundler requirement: `>= 2.0` (was `~> 1.7`)
- Rake requirement: `>= 13.0` (was `~> 10.3`)
- Removed deprecated `codeclimate-test-reporter` in favor of `simplecov`

## New Features

### Type-Safe Contracts

ServiceActor introduces a powerful **Contracts** system for validating inputs and outputs:

#### Input Contracts (expects)

```ruby
class CreateUser
  include ServiceActor
  include ServiceActor::Contracts

  expects do
    required(:email).filled(:string)
    required(:name).filled(:string)
    optional(:age).maybe(:integer)
  end

  def call
    # email and name are guaranteed to be present
    context.user = User.create!(email: context.email, name: context.name)
  end
end

# Invalid input fails automatically
result = CreateUser.call(name: "John")
result.failure?  # => true
result.errors    # => ["email is required but missing"]
```

#### Output Contracts (ensures)

```ruby
class CreateUser
  include ServiceActor
  include ServiceActor::Contracts

  expects do
    required(:email).filled(:string)
  end

  ensures do
    required(:user).type(User)
    required(:token).filled(:string)
  end

  def call
    context.user = User.create!(email: context.email)
    context.token = generate_token(context.user)
  end
end

# Missing output fails automatically
result = CreateUser.call(email: "test@example.com")
result.failure?  # => true (if we forgot to set token)
result.errors    # => ["token is required but missing"]
```

#### Advanced Validation Features

```ruby
expects do
  # Format validation
  required(:email).filled(:string).format(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)

  # Method presence
  required(:user).responds_to(:email, :name)

  # Enumerated values
  required(:status).one_of("pending", "active", "cancelled")

  # Range validation
  required(:age).filled(:integer).in_range(18..120)
end
```

#### Supported Types

- `:string`, `:integer`, `:float`, `:numeric`
- `:hash`, `:array`, `:symbol`
- `:boolean` or `:bool`
- `:time`, `:date`
- Any Ruby class or module (e.g., `User`, `ActiveRecord::Base`)

### Contract Inheritance

Contracts are inherited from parent classes:

```ruby
class BaseActor
  include ServiceActor::Contracts

  expects do
    required(:user).type(User)
  end
end

class ChildActor < BaseActor
  expects do
    required(:message).filled(:string)
  end

  # Inherits :user requirement from BaseActor
  # Must provide both :user and :message
end
```

## Benefits of Upgrading

1. **Ruby 3.x compatibility** - No more deprecation warnings about OpenStruct
2. **Rails 8.x ready** - All dependencies updated for modern Rails applications
3. **Type safety** - Optional contracts prevent runtime errors
4. **Better error messages** - Contract violations provide clear, actionable errors
5. **Modern dependencies** - Up-to-date Bundler, Rake, and testing tools
6. **Zero dependencies** - No external gems required (unlike interactor-contracts)
7. **Future-proof** - Built for the modern Ruby ecosystem

## Comparison with interactor-contracts gem

If you were using the `interactor-contracts` gem, note that ServiceActor's contracts are:

- **Built-in** - No additional gem needed
- **Zero dependencies** - No dry-validation required
- **Ruby 3.x native** - Modern implementation
- **Bidirectional** - Both input and output validation
- **Simpler DSL** - Easier to learn and use

## Need Help?

If you encounter any issues during the migration:

1. Check that you're running Ruby 3.0+
2. Ensure all dependencies are up to date with `bundle install`
3. Review the contract examples if using the new Contracts feature
4. Open an issue on [GitHub](https://github.com/n00ge/service-actor/issues) if you find a bug

For more examples and documentation, see the [README](README.md).
