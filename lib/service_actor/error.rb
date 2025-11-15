# frozen_string_literal: true

module ServiceActor
  # Internal: Error raised during ServiceActor::Context failure. The error stores
  # a copy of the failed context for debugging purposes.
  class Failure < StandardError
    # Internal: Gets the ServiceActor::Context of the ServiceActor::Failure
    # instance.
    attr_reader :context

    # Internal: Initialize a ServiceActor::Failure.
    #
    # context - A ServiceActor::Context to be stored within the
    #           ServiceActor::Failure instance. (default: nil)
    #
    # Examples
    #
    #   ServiceActor::Failure.new
    #   # => #<ServiceActor::Failure: ServiceActor::Failure>
    #
    #   context = ServiceActor::Context.new(foo: "bar")
    #   # => #<ServiceActor::Context foo="bar">
    #   ServiceActor::Failure.new(context)
    #   # => #<ServiceActor::Failure: #<ServiceActor::Context foo="bar">>
    #
    #   raise ServiceActor::Failure, context
    #   # => ServiceActor::Failure: #<ServiceActor::Context foo="bar">
    def initialize(context = nil)
      @context = context
      super
    end
  end
end
