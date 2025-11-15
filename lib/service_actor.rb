# frozen_string_literal: true

require "service_actor/context"
require "service_actor/error"
require "service_actor/hooks"
require "service_actor/organizer"
require "service_actor/contracts"

# Public: ServiceActor methods. Because ServiceActor is a module, custom ServiceActor
# classes should include ServiceActor rather than inherit from it.
#
# Examples
#
#   class MyActor
#     include ServiceActor
#
#     def call
#       puts context.foo
#     end
#   end
module ServiceActor
  # Public: Base module that provides core actor functionality.
  # This is automatically included when you include ServiceActor.
  module Base
    # Internal: Install ServiceActor's behavior in the given class.
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        include Hooks

        # Public: Gets the ServiceActor::Context of the ServiceActor instance.
        attr_reader :context
      end
    end

    # Internal: ServiceActor class methods.
    module ClassMethods
      # Public: Invoke a ServiceActor. This is the primary public API method to an
      # actor.
      #
      # context - A Hash whose key/value pairs are used in initializing a new
      #           ServiceActor::Context object. An existing ServiceActor::Context may
      #           also be given. (default: {})
      #
      # Examples
      #
      #   MyActor.call(foo: "bar")
      #   # => #<ServiceActor::Context foo="bar">
      #
      #   MyActor.call
      #   # => #<ServiceActor::Context>
      #
      # Returns the resulting ServiceActor::Context after manipulation by the
      #   actor.
      def call(context = {})
        new(context).tap(&:run).context
      end

      # Public: Invoke a ServiceActor. The "call!" method behaves identically to
      # the "call" method with one notable exception. If the context is failed
      # during invocation of the actor, the ServiceActor::Failure is raised.
      #
      # context - A Hash whose key/value pairs are used in initializing a new
      #           ServiceActor::Context object. An existing ServiceActor::Context may
      #           also be given. (default: {})
      #
      # Examples
      #
      #   MyActor.call!(foo: "bar")
      #   # => #<ServiceActor::Context foo="bar">
      #
      #   MyActor.call!
      #   # => #<ServiceActor::Context>
      #
      #   MyActor.call!(foo: "baz")
      #   # => ServiceActor::Failure: #<ServiceActor::Context foo="baz">
      #
      # Returns the resulting ServiceActor::Context after manipulation by the
      #   actor.
      # Raises ServiceActor::Failure if the context is failed.
      def call!(context = {})
        new(context).tap(&:run!).context
      end
    end

    # Internal: Initialize a ServiceActor.
    #
    # context - A Hash whose key/value pairs are used in initializing the
    #           actor's context. An existing ServiceActor::Context may also be
    #           given. (default: {})
    #
    # Examples
    #
    #   MyActor.new(foo: "bar")
    #   # => #<MyActor @context=#<ServiceActor::Context foo="bar">>
    #
    #   MyActor.new
    #   # => #<MyActor @context=#<ServiceActor::Context>>
    def initialize(context = {})
      @context = Context.build(context)
    end

    # Internal: Invoke an actor instance along with all defined hooks. The
    # "run" method is used internally by the "call" class method. The following
    # are equivalent:
    #
    #   MyActor.call(foo: "bar")
    #   # => #<ServiceActor::Context foo="bar">
    #
    #   actor = MyActor.new(foo: "bar")
    #   actor.run
    #   actor.context
    #   # => #<ServiceActor::Context foo="bar">
    #
    # After successful invocation of the actor, the instance is tracked
    # within the context. If the context is failed or any error is raised, the
    # context is rolled back.
    #
    # Returns nothing.
    def run
      run!
    rescue Failure
    end

    # Internal: Invoke a ServiceActor instance along with all defined hooks. The
    # "run!" method is used internally by the "call!" class method. The following
    # are equivalent:
    #
    #   MyActor.call!(foo: "bar")
    #   # => #<ServiceActor::Context foo="bar">
    #
    #   actor = MyActor.new(foo: "bar")
    #   actor.run!
    #   actor.context
    #   # => #<ServiceActor::Context foo="bar">
    #
    # After successful invocation of the actor, the instance is tracked
    # within the context. If the context is failed or any error is raised, the
    # context is rolled back.
    #
    # The "run!" method behaves identically to the "run" method with one notable
    # exception. If the context is failed during invocation of the actor,
    # the ServiceActor::Failure is raised.
    #
    # Returns nothing.
    # Raises ServiceActor::Failure if the context is failed.
    def run!
      with_hooks do
        validate_input_contract! if respond_to?(:validate_input_contract!, true)
        call
        context.called!(self)
        validate_output_contract! if respond_to?(:validate_output_contract!, true)
      end
    rescue
      context.rollback!
      raise
    end

    # Public: Invoke a ServiceActor instance without any hooks, tracking, or
    # rollback. It is expected that the "call" instance method is overwritten for
    # each actor class.
    #
    # Returns nothing.
    def call
    end

    # Public: Reverse prior invocation of a ServiceActor instance. Any actor
    # class that requires undoing upon downstream failure is expected to overwrite
    # the "rollback" instance method.
    #
    # Returns nothing.
    def rollback
    end
  end

  # Internal: Install ServiceActor's behavior in the given class.
  def self.included(base)
    base.class_eval do
      include Base
    end
  end
end

# Backwards compatibility aliases for migration from collectiveidea/interactor
Interactor = ServiceActor
