# frozen_string_literal: true

module ServiceActor
  # Public: Methods for declaring and validating context contracts.
  # Contracts allow you to specify required and optional attributes
  # with type checking support for both inputs and outputs.
  #
  # Examples
  #
  #   class CreateUser
  #     include ServiceActor
  #     include ServiceActor::Contracts
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

    # Internal: Install ServiceActor::Contracts behavior in the given class.
    def self.included(base)
      base.class_eval do
        extend ClassMethods
      end
    end

    # Internal: ServiceActor::Contracts class methods.
    module ClassMethods
      # Public: Define an input contract for the actor's context.
      # The contract is validated before the actor is called.
      # Contracts are inherited from parent classes and merged.
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

      # Public: Define an output contract for the actor's context.
      # The contract is validated after the actor is called, but only
      # if the context is successful.
      # Contracts are inherited from parent classes and merged.
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

      # Internal: Get the input contract defined for this actor.
      # Includes inherited contracts from parent classes.
      #
      # Returns the Contract instance or nil if no contract is defined.
      def contract
        return @contract unless superclass.respond_to?(:contract)
        return @contract unless superclass.contract

        if @contract
          superclass.contract.merge(@contract)
        else
          superclass.contract
        end
      end

      # Internal: Get the output contract defined for this actor.
      # Includes inherited contracts from parent classes.
      #
      # Returns the Contract instance or nil if no contract is defined.
      def output_contract
        return @output_contract unless superclass.respond_to?(:output_contract)
        return @output_contract unless superclass.output_contract

        if @output_contract
          superclass.output_contract.merge(@output_contract)
        else
          superclass.output_contract
        end
      end
    end

    # Internal: Validate the input contract before the actor is called.
    # This is called by the main ServiceActor module's run! method.
    #
    # Returns nothing.
    # Raises ServiceActor::Failure if validation fails.
    def validate_input_contract!
      return unless self.class.contract

      errors = self.class.contract.validate(context)
      context.fail!(errors: errors) unless errors.empty?
    end

    # Internal: Validate the output contract after the actor is called.
    # This is called by the main ServiceActor module's run! method.
    #
    # Returns nothing.
    # Raises ServiceActor::Failure if validation fails.
    def validate_output_contract!
      return unless self.class.output_contract
      return unless context.success?

      errors = self.class.output_contract.validate(context)
      context.fail!(errors: errors) unless errors.empty?
    end

    # Internal: A contract definition that specifies expected context attributes.
    class Contract
      # Internal: Initialize a new Contract.
      #
      # block - A block that defines the contract rules.
      def initialize(&block)
        @rules = {}
        instance_eval(&block) if block
        freeze_rules!
      end

      # Public: Declare a required attribute.
      #
      # name - The Symbol or String name of the required attribute.
      #
      # Returns a Rule instance for further chaining.
      # Raises ArgumentError if name is invalid or duplicate.
      def required(name)
        validated_name = validate_attribute_name!(name)
        check_duplicate!(validated_name)

        rule = Rule.new(validated_name, required: true)
        @rules[validated_name] = rule
        rule
      end

      # Public: Declare an optional attribute.
      #
      # name - The Symbol or String name of the optional attribute.
      #
      # Returns a Rule instance for further chaining.
      # Raises ArgumentError if name is invalid or duplicate.
      def optional(name)
        validated_name = validate_attribute_name!(name)
        check_duplicate!(validated_name)

        rule = Rule.new(validated_name, required: false)
        @rules[validated_name] = rule
        rule
      end

      # Internal: Validate a context against this contract.
      #
      # context - A ServiceActor::Context to validate.
      #
      # Returns an Array of error messages (empty if valid).
      def validate(context)
        @rules.values.flat_map { |rule| rule.validate(context) }.compact
      end

      # Internal: Merge another contract into this one.
      # Rules from the other contract override rules in this contract.
      #
      # other - Another Contract instance.
      #
      # Returns a new merged Contract.
      def merge(other)
        merged = Contract.allocate
        # Rules are already frozen, just merge and freeze the hash itself
        merged_rules = @rules.merge(other.instance_variable_get(:@rules))
        merged.instance_variable_set(:@rules, merged_rules.freeze)
        merged
      end

      # Internal: Get the rule names defined in this contract.
      #
      # Returns an Array of Symbol names.
      def rule_names
        @rules.keys
      end

      private

      # Internal: Validate that the attribute name is valid.
      #
      # name - The name to validate.
      #
      # Returns the symbolized name.
      # Raises ArgumentError if invalid.
      def validate_attribute_name!(name)
        raise ArgumentError, "Attribute name cannot be nil" if name.nil?

        unless name.is_a?(Symbol) || name.is_a?(String)
          raise ArgumentError, "Attribute name must be a Symbol or String, got #{name.class}"
        end

        sym_name = name.to_sym
        raise ArgumentError, "Attribute name cannot be empty" if sym_name.to_s.empty?

        sym_name
      end

      # Internal: Check if a rule already exists for this attribute.
      #
      # name - The Symbol name to check.
      #
      # Raises ArgumentError if duplicate.
      def check_duplicate!(name)
        return unless @rules.key?(name)

        raise ArgumentError, "Duplicate rule for attribute :#{name}. Each attribute can only be declared once."
      end

      # Internal: Freeze all rules to prevent mutation.
      def freeze_rules!
        @rules.each_value(&:freeze!)
        @rules.freeze
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
        @custom_validators = []
        @frozen = false
      end

      # Public: Specify that the attribute must be filled (not nil or empty).
      #
      # type - Optional Symbol type to check (:string, :integer, :hash, :array, etc.)
      #
      # Returns self for chaining.
      # Raises RuntimeError if rule is frozen.
      def filled(type = nil)
        check_frozen!
        validate_type_argument!(type) if type
        @filled = true
        @type = type
        self
      end

      # Public: Specify that the attribute may be nil.
      #
      # type - Optional Symbol type to check if value is not nil.
      #
      # Returns self for chaining.
      # Raises RuntimeError if rule is frozen.
      def maybe(type = nil)
        check_frozen!
        validate_type_argument!(type) if type
        @maybe = true
        @type = type
        self
      end

      # Public: Specify the expected type of the attribute.
      #
      # type - Symbol type to check (:string, :integer, :hash, :array, etc.)
      #        or a Class/Module.
      #
      # Returns self for chaining.
      # Raises RuntimeError if rule is frozen.
      # Raises ArgumentError if type is invalid.
      def type(type)
        check_frozen!
        validate_type_argument!(type)
        @type = type
        self
      end

      # Public: Specify that the attribute must match a format.
      #
      # pattern - A Regexp pattern to match against.
      #
      # Returns self for chaining.
      # Raises ArgumentError if pattern is not a Regexp.
      def format(pattern)
        check_frozen!
        raise ArgumentError, "Format must be a Regexp, got #{pattern.class}" unless pattern.is_a?(Regexp)

        @custom_validators << ->(value) {
          return nil if value.nil?
          return nil unless value.respond_to?(:match?)
          value.match?(pattern) ? nil : "#{@name} does not match expected format"
        }
        self
      end

      # Public: Specify that the attribute must respond to certain methods.
      #
      # methods - One or more Symbol method names.
      #
      # Returns self for chaining.
      def responds_to(*methods)
        check_frozen!
        raise ArgumentError, "At least one method name is required" if methods.empty?

        methods.each do |method|
          raise ArgumentError, "Method name must be a Symbol, got #{method.class}" unless method.is_a?(Symbol)
        end

        @custom_validators << ->(value) {
          return nil if value.nil?
          missing = methods.reject { |m| value.respond_to?(m) }
          missing.empty? ? nil : "#{@name} must respond to #{missing.join(', ')}"
        }
        self
      end

      # Public: Specify that the attribute must be one of the given values.
      #
      # values - Allowed values.
      #
      # Returns self for chaining.
      def one_of(*values)
        check_frozen!
        raise ArgumentError, "At least one value is required for one_of" if values.empty?

        @custom_validators << ->(value) {
          return nil if value.nil?
          values.include?(value) ? nil : "#{@name} must be one of #{values.inspect}, got #{value.inspect}"
        }
        self
      end

      # Public: Specify that the attribute must be within a range.
      #
      # range - A Range object.
      #
      # Returns self for chaining.
      def in_range(range)
        check_frozen!
        raise ArgumentError, "Argument must be a Range, got #{range.class}" unless range.is_a?(Range)

        @custom_validators << ->(value) {
          return nil if value.nil?
          range.cover?(value) ? nil : "#{@name} must be in range #{range}, got #{value}"
        }
        self
      end

      # Internal: Freeze the rule to prevent further modifications.
      def freeze!
        @frozen = true
        @custom_validators.freeze
        freeze
      end

      # Internal: Validate this rule against a context.
      #
      # context - A ServiceActor::Context to validate.
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

        # Run custom validators
        errors = @custom_validators.map { |validator| validator.call(value) }.compact
        return errors unless errors.empty?

        []
      end

      private

      # Internal: Check if the rule is frozen.
      #
      # Raises RuntimeError if frozen.
      def check_frozen!
        raise "Cannot modify a frozen Rule" if @frozen
      end

      # Internal: Validate that the type argument is valid.
      #
      # type - The type to validate.
      #
      # Raises ArgumentError if invalid.
      def validate_type_argument!(type)
        return if type.is_a?(Symbol)
        return if type.is_a?(Class)
        return if type.is_a?(Module)

        raise ArgumentError, "Type must be a Symbol, Class, or Module, got #{type.class}"
      end

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
        when :time
          value.is_a?(Time) || (defined?(DateTime) && value.is_a?(DateTime))
        when :date
          value.is_a?(Date)
        else
          # Allow class and module names as types
          (type.is_a?(Class) || type.is_a?(Module)) && value.is_a?(type)
        end
      end
    end
  end
end
