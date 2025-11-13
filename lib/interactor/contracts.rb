module Interactor
  # Public: Methods for declaring and validating context contracts.
  # Contracts allow you to specify required and optional attributes
  # with type checking support for both inputs and outputs.
  #
  # Examples
  #
  #   class CreateUser
  #     include Interactor
  #     include Interactor::Contracts
  #
  #     expects do
  #       required(:email).filled(:string)
  #       required(:name).filled(:string)
  #       optional(:age).maybe(:integer)
  #     end
  #
  #     ensures do
  #       required(:user).type(User)
  #       optional(:welcome_sent).type(:boolean)
  #     end
  #
  #     def call
  #       # email and name are guaranteed to be present (input)
  #       context.user = User.create!(email: context.email, name: context.name)
  #       # user is guaranteed to be set (output)
  #     end
  #   end
  module Contracts
    # Internal: Error raised when a contract validation fails.
    class ContractViolation < StandardError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
        super("Contract validation failed: #{errors.join(', ')}")
      end
    end

    # Internal: Install Interactor::Contracts behavior in the given class.
    def self.included(base)
      base.class_eval do
        extend ClassMethods
      end
    end

    # Internal: Interactor::Contracts class methods.
    module ClassMethods
      # Public: Define an input contract for the interactor's context.
      # The contract is validated before the interactor is called.
      #
      # block - A block that defines the contract using the DSL.
      #
      # Examples
      #
      #   expects do
      #     required(:email).filled(:string)
      #     optional(:age).maybe(:integer)
      #   end
      #
      # Returns nothing.
      def expects(&block)
        @contract = Contract.new(&block)
      end

      # Public: Define an output contract for the interactor's context.
      # The contract is validated after the interactor is called, but only
      # if the context is successful.
      #
      # block - A block that defines the contract using the DSL.
      #
      # Examples
      #
      #   ensures do
      #     required(:user).type(User)
      #     required(:token).filled(:string)
      #   end
      #
      # Returns nothing.
      def ensures(&block)
        @output_contract = Contract.new(&block)
      end

      # Internal: Get the input contract defined for this interactor.
      #
      # Returns the Contract instance or nil if no contract is defined.
      def contract
        @contract
      end

      # Internal: Get the output contract defined for this interactor.
      #
      # Returns the Contract instance or nil if no contract is defined.
      def output_contract
        @output_contract
      end
    end

    # Internal: Override the initialize method to validate the input contract.
    def initialize(context = {})
      super
      validate_input_contract! if self.class.contract
    end

    # Internal: Validate the output contract after the interactor is called.
    # This is called by the main Interactor module's run! method.
    #
    # Returns nothing.
    # Raises Interactor::Failure if validation fails.
    def validate_output_contract!
      return unless self.class.output_contract
      return unless context.success?

      errors = self.class.output_contract.validate(context)
      context.fail!(errors: errors) unless errors.empty?
    end

    private

    # Internal: Validate the context against the defined input contract.
    #
    # Raises ContractViolation if validation fails.
    # Returns nothing.
    def validate_input_contract!
      errors = self.class.contract.validate(context)
      context.fail!(errors: errors) unless errors.empty?
    end

    # Internal: A contract definition that specifies expected context attributes.
    class Contract
      # Internal: Initialize a new Contract.
      #
      # block - A block that defines the contract rules.
      def initialize(&block)
        @rules = []
        instance_eval(&block) if block
      end

      # Public: Declare a required attribute.
      #
      # name - The Symbol name of the required attribute.
      #
      # Returns a Rule instance for further chaining.
      def required(name)
        rule = Rule.new(name, required: true)
        @rules << rule
        rule
      end

      # Public: Declare an optional attribute.
      #
      # name - The Symbol name of the optional attribute.
      #
      # Returns a Rule instance for further chaining.
      def optional(name)
        rule = Rule.new(name, required: false)
        @rules << rule
        rule
      end

      # Internal: Validate a context against this contract.
      #
      # context - An Interactor::Context to validate.
      #
      # Returns an Array of error messages (empty if valid).
      def validate(context)
        @rules.flat_map { |rule| rule.validate(context) }.compact
      end
    end

    # Internal: A rule for a single attribute in a contract.
    class Rule
      attr_reader :name, :required

      # Internal: Initialize a new Rule.
      #
      # name - The Symbol name of the attribute.
      # required - Boolean indicating if the attribute is required.
      def initialize(name, required:)
        @name = name
        @required = required
        @type = nil
        @filled = false
        @maybe = false
      end

      # Public: Specify that the attribute must be filled (not nil or empty).
      #
      # type - Optional Symbol type to check (:string, :integer, :hash, :array, etc.)
      #
      # Returns self for chaining.
      def filled(type = nil)
        @filled = true
        @type = type
        self
      end

      # Public: Specify that the attribute may be nil.
      #
      # type - Optional Symbol type to check if value is not nil.
      #
      # Returns self for chaining.
      def maybe(type = nil)
        @maybe = true
        @type = type
        self
      end

      # Public: Specify the expected type of the attribute.
      #
      # type - Symbol type to check (:string, :integer, :hash, :array, etc.)
      #
      # Returns self for chaining.
      def type(type)
        @type = type
        self
      end

      # Internal: Validate this rule against a context.
      #
      # context - An Interactor::Context to validate.
      #
      # Returns an Array of error messages (empty if valid).
      def validate(context)
        value = context[@name]

        # Check if required attribute is missing
        if @required && value.nil?
          return ["#{@name} is required but missing"]
        end

        # Skip further validation if optional and nil
        return [] if !@required && value.nil?

        # Check if value must be filled but is empty
        if @filled && empty?(value)
          return ["#{@name} must be filled but is empty"]
        end

        # Skip type check if maybe and nil
        return [] if @maybe && value.nil?

        # Check type if specified
        if @type && !valid_type?(value, @type)
          return ["#{@name} must be of type #{@type} but got #{value.class}"]
        end

        []
      end

      private

      # Internal: Check if a value is empty.
      def empty?(value)
        value.nil? || (value.respond_to?(:empty?) && value.empty?)
      end

      # Internal: Check if a value matches the expected type.
      def valid_type?(value, type)
        case type
        when :string
          value.is_a?(String)
        when :integer
          value.is_a?(Integer)
        when :float
          value.is_a?(Float)
        when :numeric
          value.is_a?(Numeric)
        when :hash
          value.is_a?(Hash)
        when :array
          value.is_a?(Array)
        when :boolean, :bool
          value.is_a?(TrueClass) || value.is_a?(FalseClass)
        when :symbol
          value.is_a?(Symbol)
        else
          # Allow class names as types
          value.is_a?(type) if type.is_a?(Class)
        end
      end
    end
  end
end
