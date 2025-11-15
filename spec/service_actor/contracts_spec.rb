# frozen_string_literal: true

module ServiceActor
  describe Contracts do
    describe "input contracts (expects)" do
      describe "required attributes" do
        let(:interactor) do
          Class.new do
            include ServiceActor
            include ServiceActor::Contracts

            expects do
              required(:name).filled(:string)
              required(:age).filled(:integer)
            end

            def call
              context.greeting = "Hello, #{context.name}!"
            end
          end
        end

        it "passes when all required attributes are present" do
          result = interactor.call(name: "Alice", age: 30)

          expect(result).to be_success
          expect(result.greeting).to eq("Hello, Alice!")
        end

        it "fails when a required attribute is missing" do
          result = interactor.call(name: "Alice")

          expect(result).to be_failure
          expect(result.errors).to include("age is required but missing")
        end

        it "fails when multiple required attributes are missing" do
          result = interactor.call({})

          expect(result).to be_failure
          expect(result.errors).to include("name is required but missing")
          expect(result.errors).to include("age is required but missing")
        end
      end

      describe "optional attributes" do
        let(:interactor) do
          Class.new do
            include ServiceActor
            include ServiceActor::Contracts

            expects do
              required(:name).filled(:string)
              optional(:nickname).maybe(:string)
            end

            def call
              context.display_name = context.nickname || context.name
            end
          end
        end

        it "passes when optional attribute is omitted" do
          result = interactor.call(name: "Alice")

          expect(result).to be_success
          expect(result.display_name).to eq("Alice")
        end

        it "passes when optional attribute is provided" do
          result = interactor.call(name: "Alice", nickname: "Ali")

          expect(result).to be_success
          expect(result.display_name).to eq("Ali")
        end

        it "passes when optional attribute is nil" do
          result = interactor.call(name: "Alice", nickname: nil)

          expect(result).to be_success
          expect(result.display_name).to eq("Alice")
        end
      end

      describe "type validation" do
        let(:interactor) do
          Class.new do
            include ServiceActor
            include ServiceActor::Contracts

            expects do
              required(:count).filled(:integer)
            end

            def call
              context.doubled = context.count * 2
            end
          end
        end

        it "passes when type matches" do
          result = interactor.call(count: 5)

          expect(result).to be_success
          expect(result.doubled).to eq(10)
        end

        it "fails when type does not match" do
          result = interactor.call(count: "five")

          expect(result).to be_failure
          expect(result.errors).to include("count must be of type integer but got String")
        end
      end

      describe "filled validation" do
        let(:interactor) do
          Class.new do
            include ServiceActor
            include ServiceActor::Contracts

            expects do
              required(:items).filled(:array)
            end

            def call
              context.count = context.items.length
            end
          end
        end

        it "fails when value is empty" do
          result = interactor.call(items: [])

          expect(result).to be_failure
          expect(result.errors).to include("items must be filled but is empty")
        end

        it "passes when value is filled" do
          result = interactor.call(items: [1, 2, 3])

          expect(result).to be_success
          expect(result.count).to eq(3)
        end
      end

      describe "custom class types" do
        let(:user_class) { Struct.new(:name, :email) }
        let(:interactor) do
          klass = user_class
          Class.new do
            include ServiceActor
            include ServiceActor::Contracts

            expects do
              required(:user).type(klass)
            end

            def call
              context.email = context.user.email
            end
          end
        end

        it "passes when custom type matches" do
          user = user_class.new("Alice", "alice@example.com")
          result = interactor.call(user: user)

          expect(result).to be_success
          expect(result.email).to eq("alice@example.com")
        end

        it "fails when custom type does not match" do
          result = interactor.call(user: { name: "Alice", email: "alice@example.com" })

          expect(result).to be_failure
          expect(result.errors.first).to match(/user must be of type/)
        end
      end
    end

    describe "output contracts (ensures)" do
      describe "required outputs" do
        let(:interactor) do
          Class.new do
            include ServiceActor
            include ServiceActor::Contracts

            ensures do
              required(:result).filled(:string)
            end

            def call
              context.result = "success"
            end
          end
        end

        it "passes when all required outputs are present" do
          result = interactor.call

          expect(result).to be_success
          expect(result.result).to eq("success")
        end

        it "fails when required output is missing" do
          broken_interactor = Class.new do
            include ServiceActor
            include ServiceActor::Contracts

            ensures do
              required(:result).filled(:string)
            end

            def call
              # Forgot to set context.result
            end
          end

          result = broken_interactor.call

          expect(result).to be_failure
          expect(result.errors).to include("result is required but missing")
        end
      end

      describe "output validation skipped on failure" do
        let(:interactor) do
          Class.new do
            include ServiceActor
            include ServiceActor::Contracts

            ensures do
              required(:should_exist).filled(:string)
            end

            def call
              context.fail!(error: "Something went wrong")
            end
          end
        end

        it "skips output validation when context is failed" do
          result = interactor.call

          expect(result).to be_failure
          expect(result.error).to eq("Something went wrong")
          # should_exist is not in errors because output validation was skipped
          expect(result.errors).to be_nil
        end
      end
    end

    describe "contract inheritance" do
      let(:base_interactor) do
        Class.new do
          include ServiceActor
          include ServiceActor::Contracts

          expects do
            required(:user_id).filled(:integer)
          end

          def call
            context.base_called = true
          end
        end
      end

      let(:child_interactor) do
        parent = base_interactor
        Class.new(parent) do
          expects do
            required(:message).filled(:string)
          end

          def call
            super
            context.child_called = true
          end
        end
      end

      it "inherits parent contract rules" do
        result = child_interactor.call(message: "Hello")

        expect(result).to be_failure
        expect(result.errors).to include("user_id is required but missing")
      end

      it "passes when both parent and child requirements are met" do
        result = child_interactor.call(user_id: 1, message: "Hello")

        expect(result).to be_success
        expect(result.base_called).to eq(true)
        expect(result.child_called).to eq(true)
      end
    end

    describe "custom validators" do
      describe ".format" do
        let(:interactor) do
          Class.new do
            include ServiceActor
            include ServiceActor::Contracts

            expects do
              required(:email).filled(:string).format(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
            end

            def call
              context.valid = true
            end
          end
        end

        it "passes when format matches" do
          result = interactor.call(email: "test@example.com")

          expect(result).to be_success
        end

        it "fails when format does not match" do
          result = interactor.call(email: "not-an-email")

          expect(result).to be_failure
          expect(result.errors).to include("email does not match expected format")
        end
      end

      describe ".responds_to" do
        let(:interactor) do
          Class.new do
            include ServiceActor
            include ServiceActor::Contracts

            expects do
              required(:obj).responds_to(:save!, :valid?)
            end

            def call
              context.saved = context.obj.save!
            end
          end
        end

        it "passes when object responds to all methods" do
          obj = double(:obj, save!: true, valid?: true)
          result = interactor.call(obj: obj)

          expect(result).to be_success
        end

        it "fails when object does not respond to a method" do
          obj = double(:obj, save!: true)
          result = interactor.call(obj: obj)

          expect(result).to be_failure
          expect(result.errors.first).to match(/must respond to/)
        end
      end

      describe ".one_of" do
        let(:interactor) do
          Class.new do
            include ServiceActor
            include ServiceActor::Contracts

            expects do
              required(:status).one_of("pending", "active", "cancelled")
            end

            def call
              context.processed = true
            end
          end
        end

        it "passes when value is in allowed list" do
          result = interactor.call(status: "active")

          expect(result).to be_success
        end

        it "fails when value is not in allowed list" do
          result = interactor.call(status: "unknown")

          expect(result).to be_failure
          expect(result.errors.first).to match(/must be one of/)
        end
      end

      describe ".in_range" do
        let(:interactor) do
          Class.new do
            include ServiceActor
            include ServiceActor::Contracts

            expects do
              required(:age).filled(:integer).in_range(18..120)
            end

            def call
              context.adult = true
            end
          end
        end

        it "passes when value is in range" do
          result = interactor.call(age: 25)

          expect(result).to be_success
        end

        it "fails when value is below range" do
          result = interactor.call(age: 10)

          expect(result).to be_failure
          expect(result.errors.first).to match(/must be in range/)
        end

        it "fails when value is above range" do
          result = interactor.call(age: 150)

          expect(result).to be_failure
          expect(result.errors.first).to match(/must be in range/)
        end
      end
    end

    describe "argument validation" do
      it "raises error for nil attribute name" do
        expect {
          Class.new do
            include ServiceActor::Contracts

            expects do
              required(nil)
            end
          end
        }.to raise_error(ArgumentError, /cannot be nil/)
      end

      it "raises error for empty attribute name" do
        expect {
          Class.new do
            include ServiceActor::Contracts

            expects do
              required(:"")
            end
          end
        }.to raise_error(ArgumentError, /cannot be empty/)
      end

      it "raises error for duplicate attribute declaration" do
        expect {
          Class.new do
            include ServiceActor::Contracts

            expects do
              required(:name).filled(:string)
              required(:name).filled(:integer)
            end
          end
        }.to raise_error(ArgumentError, /Duplicate rule/)
      end

      it "raises error for invalid type argument" do
        expect {
          Class.new do
            include ServiceActor::Contracts

            expects do
              required(:name).type(123)
            end
          end
        }.to raise_error(ArgumentError, /Type must be/)
      end

      it "raises error for invalid format argument" do
        expect {
          Class.new do
            include ServiceActor::Contracts

            expects do
              required(:email).format("not-a-regex")
            end
          end
        }.to raise_error(ArgumentError, /Format must be a Regexp/)
      end

      it "raises error for empty responds_to" do
        expect {
          Class.new do
            include ServiceActor::Contracts

            expects do
              required(:obj).responds_to
            end
          end
        }.to raise_error(ArgumentError, /At least one method name is required/)
      end

      it "raises error for empty one_of" do
        expect {
          Class.new do
            include ServiceActor::Contracts

            expects do
              required(:status).one_of
            end
          end
        }.to raise_error(ArgumentError, /At least one value is required/)
      end

      it "raises error for non-Range in_range" do
        expect {
          Class.new do
            include ServiceActor::Contracts

            expects do
              required(:age).in_range("not-a-range")
            end
          end
        }.to raise_error(ArgumentError, /must be a Range/)
      end
    end

    describe "rollback on validation failure" do
      let(:interactor) do
        Class.new do
          include ServiceActor
          include ServiceActor::Contracts

          ensures do
            required(:output).filled(:string)
          end

          def call
            context.was_called = true
            # Forget to set output
          end

          def rollback
            context.rolled_back = true
          end
        end
      end

      it "rolls back when output validation fails" do
        result = interactor.call

        expect(result).to be_failure
        expect(result.was_called).to eq(true)
        expect(result.rolled_back).to eq(true)
      end
    end
  end
end
