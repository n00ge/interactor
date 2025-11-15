# frozen_string_literal: true

describe "Backward Compatibility" do
  describe "Interactor alias" do
    it "aliases Interactor to ServiceActor" do
      expect(Interactor).to eq(ServiceActor)
    end

    it "aliases Interactor::Context to ServiceActor::Context" do
      expect(Interactor::Context).to eq(ServiceActor::Context)
    end

    it "aliases Interactor::Failure to ServiceActor::Failure" do
      expect(Interactor::Failure).to eq(ServiceActor::Failure)
    end

    it "aliases Interactor::Hooks to ServiceActor::Hooks" do
      expect(Interactor::Hooks).to eq(ServiceActor::Hooks)
    end

    it "aliases Interactor::Organizer to ServiceActor::Organizer" do
      expect(Interactor::Organizer).to eq(ServiceActor::Organizer)
    end

    it "aliases Interactor::Contracts to ServiceActor::Contracts" do
      expect(Interactor::Contracts).to eq(ServiceActor::Contracts)
    end
  end

  describe "using old Interactor namespace" do
    let(:old_style_interactor) do
      Class.new do
        include Interactor

        def call
          context.result = context.input * 2
        end
      end
    end

    it "works with include Interactor" do
      result = old_style_interactor.call(input: 21)

      expect(result).to be_success
      expect(result.result).to eq(42)
    end

    it "rescues Interactor::Failure" do
      failing_interactor = Class.new do
        include Interactor

        def call
          context.fail!(error: "Something went wrong")
        end
      end

      begin
        failing_interactor.call!
        fail "Expected Interactor::Failure to be raised"
      rescue Interactor::Failure => e
        expect(e.context.error).to eq("Something went wrong")
      end
    end

    it "works with Interactor::Organizer" do
      step1 = Class.new do
        include Interactor

        def call
          context.steps ||= []
          context.steps << :step1
        end
      end

      step2 = Class.new do
        include Interactor

        def call
          context.steps << :step2
        end
      end

      organizer = Class.new do
        include Interactor::Organizer

        organize step1, step2
      end

      result = organizer.call

      expect(result).to be_success
      expect(result.steps).to eq([:step1, :step2])
    end

    it "works with Interactor::Contracts" do
      contract_interactor = Class.new do
        include Interactor
        include Interactor::Contracts

        expects do
          required(:name).filled(:string)
        end

        ensures do
          required(:greeting).filled(:string)
        end

        def call
          context.greeting = "Hello, #{context.name}!"
        end
      end

      result = contract_interactor.call(name: "World")

      expect(result).to be_success
      expect(result.greeting).to eq("Hello, World!")
    end
  end

  describe "mixing old and new namespaces" do
    it "allows ServiceActor and Interactor to interoperate" do
      new_style = Class.new do
        include ServiceActor

        def call
          context.from_new = true
        end
      end

      old_style = Class.new do
        include Interactor

        def call
          context.from_old = true
        end
      end

      organizer = Class.new do
        include ServiceActor::Organizer

        organize new_style, old_style
      end

      result = organizer.call

      expect(result).to be_success
      expect(result.from_new).to eq(true)
      expect(result.from_old).to eq(true)
    end

    it "shares context between old and new style actors" do
      producer = Class.new do
        include Interactor

        def call
          context.data = { key: "value" }
        end
      end

      consumer = Class.new do
        include ServiceActor

        def call
          context.consumed = context.data[:key]
        end
      end

      organizer = Class.new do
        include Interactor::Organizer

        organize producer, consumer
      end

      result = organizer.call

      expect(result).to be_success
      expect(result.consumed).to eq("value")
    end
  end
end
