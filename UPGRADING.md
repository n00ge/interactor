# Upgrading to Interactor 4.0

Interactor 4.0 has been modernized for Ruby 3.x and Rails 8.x compatibility. This guide will help you upgrade from Interactor 3.x.

## Breaking Changes

### Ruby Version Requirement

Interactor 4.0 requires **Ruby 3.0.0 or higher**. If you're using an older Ruby version, you must upgrade first.

```ruby
# .ruby-version
3.0.0  # or higher
```

### OpenStruct Removed

The `Context` class no longer inherits from `OpenStruct` (which is deprecated in Ruby 3.2+). We now use a custom implementation that maintains the same API.

**This change is backwards compatible** - your existing code should continue to work without modifications:

```ruby
# All of these still work exactly as before
context = Interactor::Context.new(foo: "bar")
context.foo          # => "bar"
context.baz = "qux"  # Dynamic setters still work
context[:foo]        # => "bar" (hash-like access still works)
```

### Dependency Updates

- Bundler requirement: `>= 2.0` (was `~> 1.7`)
- Rake requirement: `>= 13.0` (was `~> 10.3`)
- RSpec updated to `~> 3.12`
- Removed deprecated `codeclimate-test-reporter` in favor of `simplecov`

## New Features

### Contracts for Type Safety

Interactor 4.0 introduces a new **Contracts** system that allows you to declare required and optional context attributes with type validation:

```ruby
class CreateUser
  include Interactor
  include Interactor::Contracts

  expects do
    required(:email).filled(:string)
    required(:name).filled(:string)
    optional(:age).maybe(:integer)
    optional(:preferences).type(:hash)
  end

  def call
    # email and name are guaranteed to be present and non-empty strings
    # age, if present, is guaranteed to be an integer
    User.create!(
      email: context.email,
      name: context.name,
      age: context.age
    )
  end
end

# Valid call
CreateUser.call(email: "user@example.com", name: "John Doe", age: 30)
# => Success

# Invalid call - missing required field
CreateUser.call(name: "John Doe")
# => Failure with context.errors: ["email is required but missing"]

# Invalid call - wrong type
CreateUser.call(email: "user@example.com", name: "John", age: "thirty")
# => Failure with context.errors: ["age must be of type integer but got String"]
```

#### Contract DSL Reference

**Declaring attributes:**
- `required(:attribute_name)` - Attribute must be present
- `optional(:attribute_name)` - Attribute may be omitted

**Validation methods:**
- `.filled(type)` - Value must not be nil or empty, optionally check type
- `.maybe(type)` - Value may be nil, but if present must match type
- `.type(type)` - Value must match the specified type

**Supported types:**
- `:string` - String
- `:integer` - Integer
- `:float` - Float
- `:numeric` - Any Numeric
- `:hash` - Hash
- `:array` - Array
- `:boolean` or `:bool` - TrueClass or FalseClass
- `:symbol` - Symbol
- Any Ruby class (e.g., `User`, `ActiveRecord::Base`)

#### Contract Validation Behavior

When contracts are violated:
1. The context is automatically failed
2. Errors are added to `context.errors` as an array of messages
3. An `Interactor::Failure` exception is raised (caught by `call`, raised by `call!`)

```ruby
result = CreateUser.call(name: "John")
result.failure?  # => true
result.errors    # => ["email is required but missing"]
```

## Migration Steps

1. **Update your Ruby version** to 3.0 or higher
   ```bash
   # .ruby-version
   3.0.0
   ```

2. **Update your Gemfile**
   ```ruby
   gem 'interactor', '~> 4.0'
   ```

3. **Run bundle update**
   ```bash
   bundle update interactor
   ```

4. **Test your application** - The changes are designed to be backwards compatible

5. **(Optional) Add contracts** to your interactors for better type safety:
   ```ruby
   class MyInteractor
     include Interactor
     include Interactor::Contracts  # Add this

     expects do                      # Add contract definitions
       required(:user).filled
       required(:params).type(:hash)
     end

     # ... rest of your code
   end
   ```

## Benefits of Upgrading

1. **Ruby 3.x compatibility** - No more deprecation warnings about OpenStruct
2. **Rails 8.x ready** - All dependencies updated for modern Rails applications
3. **Type safety** - Optional contracts prevent runtime errors
4. **Better error messages** - Contract violations provide clear, actionable errors
5. **Modern dependencies** - Up-to-date Bundler, Rake, and testing tools
6. **Future-proof** - Built for the modern Ruby ecosystem

## Need Help?

If you encounter any issues during the upgrade:

1. Check that you're running Ruby 3.0+
2. Ensure all dependencies are up to date with `bundle update`
3. Review the contract examples if using the new Contracts feature
4. Open an issue on GitHub if you find a bug

For more examples and documentation, see the [README](README.md).
