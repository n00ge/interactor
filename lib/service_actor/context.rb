# frozen_string_literal: true

module ServiceActor
  # Public: The object for tracking state of a ServiceActor's invocation. The
  # context is used to initialize the actor with the information required
  # for invocation. The actor manipulates the context to produce the result
  # of invocation.
  #
  # The context is the mechanism by which success and failure are determined and
  # the context is responsible for tracking individual actor invocations
  # for the purpose of rollback.
  #
  # The context may be manipulated using arbitrary getter and setter methods.
  #
  # Examples
  #
  #   context = ServiceActor::Context.new
  #   # => #<ServiceActor::Context>
  #   context.foo = "bar"
  #   # => "bar"
  #   context
  #   # => #<ServiceActor::Context foo="bar">
  #   context.hello = "world"
  #   # => "world"
  #   context
  #   # => #<ServiceActor::Context foo="bar" hello="world">
  #   context.foo = "baz"
  #   # => "baz"
  #   context
  #   # => #<ServiceActor::Context foo="baz" hello="world">
  class Context
    # Internal: Initialize a new Context with the given attributes.
    #
    # attributes - A Hash of attributes to initialize the context with.
    #
    # Returns a new Context instance.
    def initialize(attributes = {})
      @table = {}
      attributes.each { |key, value| self[key] = value }
    end

    # Internal: Get the value of an attribute.
    #
    # key - The Symbol or String key of the attribute.
    #
    # Returns the value of the attribute or nil if not set.
    def [](key)
      @table[key.to_sym]
    end

    # Internal: Set the value of an attribute.
    #
    # key - The Symbol or String key of the attribute.
    # value - The value to set.
    #
    # Returns the value.
    def []=(key, value)
      @table[key.to_sym] = value
    end

    # Internal: Convert the context to a hash.
    #
    # Returns a Hash representation of the context.
    def to_h
      @table.dup
    end

    # Internal: Iterate over each key-value pair in the context.
    #
    # Yields each key-value pair.
    #
    # Returns nothing.
    def each_pair(&block)
      @table.each_pair(&block)
    end

    # Internal: Check if the context responds to a method.
    #
    # method_name - The Symbol or String name of the method.
    # include_private - Whether to include private methods (default: false).
    #
    # Returns true if the method exists or is a dynamic getter/setter.
    def respond_to_missing?(method_name, include_private = false)
      true
    end

    # Internal: Handle dynamic getter and setter methods.
    #
    # method_name - The Symbol name of the method.
    # args - Arguments passed to the method.
    #
    # Returns the value for getters or sets the value for setters.
    def method_missing(method_name, *args)
      if method_name.to_s.end_with?("=")
        self[method_name.to_s.chomp("=")] = args.first
      else
        self[method_name]
      end
    end

    # Internal: Access the underlying hash table (for compatibility).
    #
    # Returns the internal hash table.
    def table
      @table
    end
    private :table

    # Internal: Provide modifiable access to the table (for compatibility).
    #
    # Returns the internal hash table.
    def modifiable
      @table
    end
    private :modifiable

    # Internal: Initialize a ServiceActor::Context or preserve an existing one.
    # If the argument given is a ServiceActor::Context, the argument is returned.
    # Otherwise, a new ServiceActor::Context is initialized from the provided
    # hash.
    #
    # The "build" method is used during actor initialization.
    #
    # context - A Hash whose key/value pairs are used in initializing a new
    #           ServiceActor::Context object. If an existing ServiceActor::Context
    #           is given, it is simply returned. (default: {})
    #
    # Examples
    #
    #   context = ServiceActor::Context.build(foo: "bar")
    #   # => #<ServiceActor::Context foo="bar">
    #   context.object_id
    #   # => 2170969340
    #   context = ServiceActor::Context.build(context)
    #   # => #<ServiceActor::Context foo="bar">
    #   context.object_id
    #   # => 2170969340
    #
    # Returns the ServiceActor::Context.
    def self.build(context = {})
      self === context ? context : new(context)
    end

    # Public: Whether the ServiceActor::Context is successful. By default, a new
    # context is successful and only changes when explicitly failed.
    #
    # The "success?" method is the inverse of the "failure?" method.
    #
    # Examples
    #
    #   context = ServiceActor::Context.new
    #   # => #<ServiceActor::Context>
    #   context.success?
    #   # => true
    #   context.fail!
    #   # => ServiceActor::Failure: #<ServiceActor::Context>
    #   context.success?
    #   # => false
    #
    # Returns true by default or false if failed.
    def success?
      !failure?
    end

    # Public: Whether the ServiceActor::Context has failed. By default, a new
    # context is successful and only changes when explicitly failed.
    #
    # The "failure?" method is the inverse of the "success?" method.
    #
    # Examples
    #
    #   context = ServiceActor::Context.new
    #   # => #<ServiceActor::Context>
    #   context.failure?
    #   # => false
    #   context.fail!
    #   # => ServiceActor::Failure: #<ServiceActor::Context>
    #   context.failure?
    #   # => true
    #
    # Returns false by default or true if failed.
    def failure?
      @failure || false
    end

    # Public: Fail the ServiceActor::Context. Failing a context raises an error
    # that may be rescued by the calling actor. The context is also flagged
    # as having failed.
    #
    # Optionally the caller may provide a hash of key/value pairs to be merged
    # into the context before failure.
    #
    # context - A Hash whose key/value pairs are merged into the existing
    #           ServiceActor::Context instance. (default: {})
    #
    # Examples
    #
    #   context = ServiceActor::Context.new
    #   # => #<ServiceActor::Context>
    #   context.fail!
    #   # => ServiceActor::Failure: #<ServiceActor::Context>
    #   context.fail! rescue false
    #   # => false
    #   context.fail!(foo: "baz")
    #   # => ServiceActor::Failure: #<ServiceActor::Context foo="baz">
    #
    # Raises ServiceActor::Failure initialized with the ServiceActor::Context.
    def fail!(context = {})
      context.each { |key, value| modifiable[key.to_sym] = value }
      @failure = true
      raise Failure, self
    end

    # Internal: Track that a ServiceActor has been called. The "called!" method
    # is used by the actor being invoked with this context. After an
    # actor is successfully called, the actor instance is tracked in
    # the context for the purpose of potential future rollback.
    #
    # actor - A ServiceActor instance that has been successfully called.
    #
    # Returns nothing.
    def called!(actor)
      _called << actor
    end

    # Public: Roll back the ServiceActor::Context. Any actors to which this
    # context has been passed and which have been successfully called are asked
    # to roll themselves back by invoking their "rollback" instance methods.
    #
    # Examples
    #
    #   context = MyActor.call(foo: "bar")
    #   # => #<ServiceActor::Context foo="baz">
    #   context.rollback!
    #   # => true
    #   context
    #   # => #<ServiceActor::Context foo="bar">
    #
    # Returns true if rolled back successfully or false if already rolled back.
    def rollback!
      return false if @rolled_back
      _called.reverse_each(&:rollback)
      @rolled_back = true
    end

    # Internal: An Array of successfully called ServiceActor instances invoked
    # against this ServiceActor::Context instance.
    #
    # Examples
    #
    #   context = ServiceActor::Context.new
    #   # => #<ServiceActor::Context>
    #   context._called
    #   # => []
    #
    #   context = MyActor.call(foo: "bar")
    #   # => #<ServiceActor::Context foo="baz">
    #   context._called
    #   # => [#<MyActor @context=#<ServiceActor::Context foo="baz">>]
    #
    # Returns an Array of ServiceActor instances or an empty Array.
    def _called
      @called ||= []
    end
  end
end
