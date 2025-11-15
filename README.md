# ServiceActor

[![Gem Version](https://img.shields.io/gem/v/service-actor.svg?style=flat-square)](http://rubygems.org/gems/service-actor)
[![Build Status](https://img.shields.io/github/actions/workflow/status/n00ge/service-actor/ci.yml?style=flat-square)](https://github.com/n00ge/service-actor/actions)

Simple service objects (actors) with type-safe contracts for Ruby 3.x.

## Attribution

ServiceActor is a modernized fork of [collectiveidea/interactor](https://github.com/collectiveidea/interactor), originally created by [Collective Idea](https://collectiveidea.com). We are grateful for their pioneering work on the interactor pattern in Ruby.

**Key differences from the original:**
- Ruby 3.x compatibility (no deprecated OpenStruct)
- Type-safe contracts with `expects`/`ensures` DSL
- Zero external dependencies
- Modern gem infrastructure

## Getting Started

Add ServiceActor to your Gemfile and `bundle install`.

```ruby
gem "service-actor", "~> 1.0"
```

## Migration from collectiveidea/interactor

ServiceActor provides backward compatibility aliases for `Interactor`. Your existing code should continue to work:

```ruby
# These work the same
include Interactor           # Still works (aliased)
include ServiceActor         # New preferred way

# These are equivalent
Interactor::Context          # Aliased to ServiceActor::Context
Interactor::Failure          # Aliased to ServiceActor::Failure
Interactor::Organizer        # Aliased to ServiceActor::Organizer
Interactor::Contracts        # Aliased to ServiceActor::Contracts
```

We recommend gradually updating your code to use `ServiceActor` for clarity.

## What is a ServiceActor?

A service actor is a simple, single-purpose object.

Service actors are used to encapsulate your application's
[business logic](http://en.wikipedia.org/wiki/Business_logic). Each actor
represents one thing that your application *does*.

### Context

An actor is given a *context*. The context contains everything the
actor needs to do its work.

When an actor does its single purpose, it affects its given context.

#### Adding to the Context

As an actor runs it can add information to the context.

```ruby
context.user = user
```

#### Failing the Context

When something goes wrong in your actor, you can flag the context as
failed.

```ruby
context.fail!
```

When given a hash argument, the `fail!` method can also update the context. The
following are equivalent:

```ruby
context.error = "Boom!"
context.fail!
```

```ruby
context.fail!(error: "Boom!")
```

You can ask a context if it's a failure:

```ruby
context.failure? # => false
context.fail!
context.failure? # => true
```

or if it's a success.

```ruby
context.success? # => true
context.fail!
context.success? # => false
```

#### Dealing with Failure

`context.fail!` always throws an exception of type `ServiceActor::Failure`.

Normally, however, these exceptions are not seen. In the recommended usage, the controller invokes the actor using the class method `call`, then checks the `success?` method of the context.

This works because the `call` class method swallows exceptions. When unit testing an actor, if calling custom business logic methods directly and bypassing `call`, be aware that `fail!` will generate such exceptions.

See *Actors in the Controller*, below, for the recommended usage of `call` and `success?`.

### Contracts (Type Safety)

You can declare required and optional context attributes with type validation using contracts for both inputs and outputs.

#### Input Contracts (expects)

Use `expects` to validate inputs before the actor runs:

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
    User.create!(email: context.email, name: context.name, age: context.age)
  end
end
```

If input validation fails, the context is automatically failed with errors:

```ruby
result = CreateUser.call(name: "John")
result.failure?  # => true
result.errors    # => ["email is required but missing"]
```

#### Output Contracts (ensures)

Use `ensures` to validate outputs after the actor runs successfully:

```ruby
class CreateUser
  include ServiceActor
  include ServiceActor::Contracts

  expects do
    required(:email).filled(:string)
    required(:name).filled(:string)
  end

  ensures do
    required(:user).type(User)
    required(:token).filled(:string)
  end

  def call
    context.user = User.create!(email: context.email, name: context.name)
    context.token = generate_token(context.user)
    # If we forget to set user or token, ensures will catch it!
  end
end
```

Output contracts are validated **only if the actor succeeds**. If the context is failed during execution, output validation is skipped.

```ruby
result = CreateUser.call(email: "test@example.com", name: "John")
result.success?  # => true
result.user      # => #<User> (guaranteed to exist and be correct type)

# If output validation fails:
result = CreateUser.call(email: "test@example.com", name: "John")
result.failure?  # => true
result.errors    # => ["user is required but missing"]
```

#### Benefits of Output Contracts

1. **Documentation** - Clearly see what an actor produces
2. **Type Safety** - Catch missing or incorrect outputs at runtime
3. **Organizer Validation** - Ensure each step produces what the next step needs
4. **Fail Fast** - Detect bugs immediately rather than later in the call chain

#### Advanced Contract Features

**Format Validation:**
```ruby
expects do
  required(:email).filled(:string).format(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
end
```

**Method Presence:**
```ruby
expects do
  required(:user).responds_to(:email, :name, :save!)
end
```

**Enumerated Values:**
```ruby
expects do
  required(:status).one_of("pending", "active", "cancelled")
end
```

**Range Validation:**
```ruby
expects do
  required(:age).filled(:integer).in_range(18..120)
end
```

#### Contract DSL Reference

**Declaring Attributes:**
- `required(:attribute)` - Attribute must be present
- `optional(:attribute)` - Attribute may be omitted

**Validation Methods:**
- `.filled(type)` - Must not be nil or empty, optionally check type
- `.maybe(type)` - May be nil, but if present must match type
- `.type(type)` - Must match the specified type
- `.format(regex)` - Must match the regular expression
- `.responds_to(*methods)` - Must respond to the given methods
- `.one_of(*values)` - Must be one of the specified values
- `.in_range(range)` - Must be within the specified range

**Supported Types:**

`:string`, `:integer`, `:float`, `:numeric`, `:hash`, `:array`, `:boolean`/`:bool`, `:symbol`, `:time`, `:date`, or any Ruby class/module.

**Examples:**

```ruby
class ProcessPayment
  include ServiceActor::Contracts

  expects do
    required(:user).type(User)
    required(:amount).filled(:integer).in_range(1..100_000)
    required(:params).filled(:hash)
    optional(:notify).maybe(:boolean)
  end

  ensures do
    required(:payment).type(Payment)
    required(:receipt_id).filled(:string)
    optional(:notification_sent).type(:boolean)
  end
end
```

### Hooks

#### Before Hooks

Sometimes an actor needs to prepare its context before the actor is
even run. This can be done with before hooks on the actor.

```ruby
before do
  context.emails_sent = 0
end
```

A symbol argument can also be given, rather than a block.

```ruby
before :zero_emails_sent

def zero_email_sent
  context.emails_sent = 0
end
```

#### After Hooks

Actors can also perform teardown operations after the actor instance
is run.

```ruby
after do
  context.user.reload
end
```

NB: After hooks are only run on success. If the `fail!` method is called, the actor's after hooks are not run.

#### Around Hooks

You can also define around hooks in the same way as before or after hooks, using
either a block or a symbol method name. The difference is that an around block
or method accepts a single argument. Invoking the `call` method on that argument
will continue invocation of the actor. For example, with a block:

```ruby
around do |actor|
  context.start_time = Time.now
  actor.call
  context.finish_time = Time.now
end
```

With a method:

```ruby
around :time_execution

def time_execution(actor)
  context.start_time = Time.now
  actor.call
  context.finish_time = Time.now
end
```

NB: If the `fail!` method is called, all of the actor's around hooks cease execution, and no code after `actor.call` will be run.

#### Hook Sequence

Before hooks are invoked in the order in which they were defined while after
hooks are invoked in the opposite order. Around hooks are invoked outside of any
defined before and after hooks. For example:

```ruby
around do |actor|
  puts "around before 1"
  actor.call
  puts "around after 1"
end

around do |actor|
  puts "around before 2"
  actor.call
  puts "around after 2"
end

before do
  puts "before 1"
end

before do
  puts "before 2"
end

after do
  puts "after 1"
end

after do
  puts "after 2"
end
```

will output:

```
around before 1
around before 2
before 1
before 2
after 2
after 1
around after 2
around after 1
```

#### Actor Concerns

An actor can define multiple before/after hooks, allowing common hooks to
be extracted into actor concerns.

```ruby
module ActorTimer
  extend ActiveSupport::Concern

  included do
    around do |actor|
      context.start_time = Time.now
      actor.call
      context.finish_time = Time.now
    end
  end
end
```

### An Example Actor

Your application could use an actor to authenticate a user.

```ruby
class AuthenticateUser
  include ServiceActor

  def call
    if user = User.authenticate(context.email, context.password)
      context.user = user
      context.token = user.secret_token
    else
      context.fail!(message: "authenticate_user.failure")
    end
  end
end
```

To define an actor, simply create a class that includes the `ServiceActor`
module and give it a `call` instance method. The actor can access its
`context` from within `call`.

## Actors in the Controller

Most of the time, your application will use its actors from its
controllers. The following controller:

```ruby
class SessionsController < ApplicationController
  def create
    if user = User.authenticate(session_params[:email], session_params[:password])
      session[:user_token] = user.secret_token
      redirect_to user
    else
      flash.now[:message] = "Please try again."
      render :new
    end
  end

  private

  def session_params
    params.require(:session).permit(:email, :password)
  end
end
```

can be refactored to:

```ruby
class SessionsController < ApplicationController
  def create
    result = AuthenticateUser.call(session_params)

    if result.success?
      session[:user_token] = result.token
      redirect_to result.user
    else
      flash.now[:message] = t(result.message)
      render :new
    end
  end

  private

  def session_params
    params.require(:session).permit(:email, :password)
  end
end
```

The `call` class method is the proper way to invoke an actor. The hash
argument is converted to the actor instance's context. The `call` instance
method is invoked along with any hooks that the actor might define.
Finally, the context (along with any changes made to it) is returned.

## When to Use a ServiceActor

Given the user authentication example, your controller may look like:

```ruby
class SessionsController < ApplicationController
  def create
    result = AuthenticateUser.call(session_params)

    if result.success?
      session[:user_token] = result.token
      redirect_to result.user
    else
      flash.now[:message] = t(result.message)
      render :new
    end
  end

  private

  def session_params
    params.require(:session).permit(:email, :password)
  end
end
```

For such a simple use case, using an actor can actually require *more*
code. So why use an actor?

### Clarity

A glance at your `app/actors` directory gives any developer a quick understanding of everything the application *does*.

```
▾ app/
  ▸ controllers/
  ▸ helpers/
  ▾ actors/
      authenticate_user.rb
      cancel_account.rb
      publish_post.rb
      register_user.rb
      remove_post.rb
  ▸ mailers/
  ▸ models/
  ▸ views/
```

**TIP:** Name your actors after your business logic, not your
implementation. `CancelAccount` will serve you better than `DestroyUser` as the
account cancellation interaction takes on more responsibility in the future.

### The Future™

**SPOILER ALERT:** Your use case won't *stay* so simple.

A simple task like authenticating a user will eventually take on multiple responsibilities:

* Welcoming back a user who hadn't logged in for a while
* Prompting a user to update his or her password
* Locking out a user in the case of too many failed attempts
* Sending the lock-out email notification

The list goes on, and as that list grows, so does your controller. This is how
fat controllers are born.

If instead you use an actor right away, as responsibilities are added, your
controller (and its tests) change very little or not at all. Choosing the right
kind of actor can also prevent simply shifting those added responsibilities
to the actor.

## Kinds of Actors

There are two kinds of actors built into ServiceActor: basic
actors and organizers.

### Actors

A basic actor is a class that includes `ServiceActor` and defines `call`.

```ruby
class AuthenticateUser
  include ServiceActor

  def call
    if user = User.authenticate(context.email, context.password)
      context.user = user
      context.token = user.secret_token
    else
      context.fail!(message: "authenticate_user.failure")
    end
  end
end
```

Basic actors are the building blocks. They are your application's
single-purpose units of work.

### Organizers

An organizer is an important variation on the basic actor. Its single
purpose is to run *other* actors.

```ruby
class PlaceOrder
  include ServiceActor::Organizer

  organize CreateOrder, ChargeCard, SendThankYou
end
```

In the controller, you can run the `PlaceOrder` organizer just like you would
any other actor:

```ruby
class OrdersController < ApplicationController
  def create
    result = PlaceOrder.call(order_params: order_params)

    if result.success?
      redirect_to result.order
    else
      @order = result.order
      render :new
    end
  end

  private

  def order_params
    params.require(:order).permit!
  end
end
```

The organizer passes its context to the actors that it organizes, one at a
time and in order. Each actor may change that context before it's passed
along to the next actor.

#### Rollback

If any one of the organized actors fails its context, the organizer stops.
If the `ChargeCard` actor fails, `SendThankYou` is never called.

In addition, any actors that had already run are given the chance to undo
themselves, in reverse order. Simply define the `rollback` method on your
actors:

```ruby
class CreateOrder
  include ServiceActor

  def call
    order = Order.create(order_params)

    if order.persisted?
      context.order = order
    else
      context.fail!
    end
  end

  def rollback
    context.order.destroy
  end
end
```

**NOTE:** The actor that fails is *not* rolled back. Because every
actor should have a single purpose, there should be no need to clean up
after any failed actor.

## Testing Actors

When written correctly, an actor is easy to test because it only *does* one
thing. Take the following actor:

```ruby
class AuthenticateUser
  include ServiceActor

  def call
    if user = User.authenticate(context.email, context.password)
      context.user = user
      context.token = user.secret_token
    else
      context.fail!(message: "authenticate_user.failure")
    end
  end
end
```

You can test just this actor's single purpose and how it affects the
context.

```ruby
describe AuthenticateUser do
  subject(:context) { AuthenticateUser.call(email: "john@example.com", password: "secret") }

  describe ".call" do
    context "when given valid credentials" do
      let(:user) { double(:user, secret_token: "token") }

      before do
        allow(User).to receive(:authenticate).with("john@example.com", "secret").and_return(user)
      end

      it "succeeds" do
        expect(context).to be_a_success
      end

      it "provides the user" do
        expect(context.user).to eq(user)
      end

      it "provides the user's secret token" do
        expect(context.token).to eq("token")
      end
    end

    context "when given invalid credentials" do
      before do
        allow(User).to receive(:authenticate).with("john@example.com", "secret").and_return(nil)
      end

      it "fails" do
        expect(context).to be_a_failure
      end

      it "provides a failure message" do
        expect(context.message).to be_present
      end
    end
  end
end
```

We use RSpec but the same approach applies to any testing framework.

### Isolation

You may notice that we stub `User.authenticate` in our test rather than creating
users in the database. That's because our purpose in
`spec/actors/authenticate_user_spec.rb` is to test just the
`AuthenticateUser` actor. The `User.authenticate` method is put through its
own paces in `spec/models/user_spec.rb`.

It's a good idea to define your own interfaces to your models. Doing so makes it
easy to draw a line between which responsibilities belong to the actor and
which to the model. The `User.authenticate` method is a good, clear line.
Imagine the actor otherwise:

```ruby
class AuthenticateUser
  include ServiceActor

  def call
    user = User.where(email: context.email).first

    # Yuck!
    if user && BCrypt::Password.new(user.password_digest) == context.password
      context.user = user
    else
      context.fail!(message: "authenticate_user.failure")
    end
  end
end
```

It would be very difficult to test this actor in isolation and even if you
did, as soon as you change your ORM or your encryption algorithm (both model
concerns), your actors (business concerns) break.

*Draw clear lines.*

### Integration

While it's important to test your actors in isolation, it's just as
important to write good integration or acceptance tests.

One of the pitfalls of testing in isolation is that when you stub a method, you
could be hiding the fact that the method is broken, has changed or doesn't even
exist.

When you write full-stack tests that tie all of the pieces together, you can be
sure that your application's individual pieces are working together as expected.
That becomes even more important when you add a new layer to your code like
actors.

**TIP:** If you track your test coverage, try for 100% coverage *before*
integrations tests. Then keep writing integration tests until you sleep well at
night.

### Controllers

One of the advantages of using actors is how much they simplify controllers
and their tests. Because you're testing your actors thoroughly in isolation
as well as in integration tests (right?), you can remove your business logic
from your controller tests.

```ruby
class SessionsController < ApplicationController
  def create
    result = AuthenticateUser.call(session_params)

    if result.success?
      session[:user_token] = result.token
      redirect_to result.user
    else
      flash.now[:message] = t(result.message)
      render :new
    end
  end

  private

  def session_params
    params.require(:session).permit(:email, :password)
  end
end
```

```ruby
describe SessionsController do
  describe "#create" do
    before do
      expect(AuthenticateUser).to receive(:call).once.with(email: "john@doe.com", password: "secret").and_return(context)
    end

    context "when successful" do
      let(:user) { double(:user, id: 1) }
      let(:context) { double(:context, success?: true, user: user, token: "token") }

      it "saves the user's secret token in the session" do
        expect {
          post :create, session: { email: "john@doe.com", password: "secret" }
        }.to change {
          session[:user_token]
        }.from(nil).to("token")
      end

      it "redirects to the homepage" do
        response = post :create, session: { email: "john@doe.com", password: "secret" }

        expect(response).to redirect_to(user_path(user))
      end
    end

    context "when unsuccessful" do
      let(:context) { double(:context, success?: false, message: "message") }

      it "sets a flash message" do
        expect {
          post :create, session: { email: "john@doe.com", password: "secret" }
        }.to change {
          flash[:message]
        }.from(nil).to(I18n.translate("message"))
      end

      it "renders the login form" do
        response = post :create, session: { email: "john@doe.com", password: "secret" }

        expect(response).to render_template(:new)
      end
    end
  end
end
```

This controller test will have to change very little during the life of the
application because all of the magic happens in the actor.

### Rails

We love Rails, and we use ServiceActor with Rails. We put our actors in `app/actors` and we name them as verbs:

* `AddProductToCart`
* `AuthenticateUser`
* `PlaceOrder`
* `RegisterUser`
* `RemoveProductFromCart`

## Contributions

ServiceActor is open source and contributions from the community are encouraged!
No contribution is too small.

## Thank You

Special thanks to:

- **[Collective Idea](https://collectiveidea.com)** for creating the original [interactor](https://github.com/collectiveidea/interactor) gem
- **[Attila Domokos](https://github.com/adomokos)** for [LightService](https://github.com/adomokos/light-service), which inspired the original interactor gem

ServiceActor builds on the excellent foundation laid by these projects.

## License

ServiceActor is released under the [MIT License](MIT-LICENSE).
