# frozen_string_literal: true

module ServiceActor
  # Public: ServiceActor::Organizer methods. Because ServiceActor::Organizer is a
  # module, custom ServiceActor::Organizer classes should include
  # ServiceActor::Organizer rather than inherit from it.
  #
  # Examples
  #
  #   class MyOrganizer
  #     include ServiceActor::Organizer
  #
  #     organize ActorOne, ActorTwo
  #   end
  module Organizer
    # Internal: Install ServiceActor::Organizer's behavior in the given class.
    def self.included(base)
      base.class_eval do
        include ServiceActor::Base

        extend ClassMethods
        include InstanceMethods
      end
    end

    # Internal: ServiceActor::Organizer class methods.
    module ClassMethods
      # Public: Declare ServiceActors to be invoked as part of the
      # ServiceActor::Organizer's invocation. These actors are invoked in
      # the order in which they are declared.
      #
      # actors - Zero or more (or an Array of) ServiceActor classes.
      #
      # Examples
      #
      #   class MyFirstOrganizer
      #     include ServiceActor::Organizer
      #
      #     organize ActorOne, ActorTwo
      #   end
      #
      #   class MySecondOrganizer
      #     include ServiceActor::Organizer
      #
      #     organize [ActorThree, ActorFour]
      #   end
      #
      # Returns nothing.
      def organize(*actors)
        @organized = actors.flatten
      end

      # Internal: An Array of declared ServiceActors to be invoked.
      #
      # Examples
      #
      #   class MyOrganizer
      #     include ServiceActor::Organizer
      #
      #     organize ActorOne, ActorTwo
      #   end
      #
      #   MyOrganizer.organized
      #   # => [ActorOne, ActorTwo]
      #
      # Returns an Array of ServiceActor classes or an empty Array.
      def organized
        @organized ||= []
      end
    end

    # Internal: ServiceActor::Organizer instance methods.
    module InstanceMethods
      # Internal: Invoke the organized ServiceActors. A ServiceActor::Organizer is
      # expected not to define its own "#call" method in favor of this default
      # implementation.
      #
      # Returns nothing.
      def call
        self.class.organized.each do |actor|
          actor.call!(context)
        end
      end
    end
  end
end
