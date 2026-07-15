require 'rails_helper'

module Kintide
  module StateMachine
    RSpec.describe Bridge do
      described_module = described_class

      temporary_model 'AlarmStateMachine', super_class: Machine do
        state :disarmed, initial: true do
          event :arm, to: :armed
        end

        state :armed do
          event :disarm, to: :disarmed
          event :trigger, to: :triggered
        end

        state :triggered do
          event :silence, to: :disarmed
        end
      end

      temporary_model 'ModelWithStateMachine', super_class: nil do
        include ActiveModel::Model
        include ActiveModel::Attributes
        include described_module[AlarmStateMachine]

        attribute :state

        def initialize(attributes = {})
          super(state: AlarmStateMachine.initial, **attributes)
        end

        def save! = false
      end

      it 'updates the record after transitioning' do
        aggregate_failures do
          [
            %w[disarmed arm armed],
            %w[armed disarm disarmed],
            %w[armed trigger triggered],
            %w[triggered silence disarmed],
          ].each do |(from, event, to)|
            record = ModelWithStateMachine.new(state: from)

            record.invoke event

            expect(record.state).to eq to
          end
        end
      end

      context 'with a prefix' do
        temporary_model 'ModelWithStateMachine', super_class: nil do
          include ActiveModel::Model
          include ActiveModel::Attributes
          include described_module[AlarmStateMachine, prefix: :car_alarm]

          attribute :car_alarm_state

          def initialize(attributes = {})
            super(car_alarm_state: AlarmStateMachine.initial, **attributes)
          end

          def save! = false
        end

        let(:record) { ModelWithStateMachine.new }

        it 'prefixes the state machine' do
          expect(record.car_alarm_machine).to be_an AlarmStateMachine
        end

        it 'prefixes the state attribute' do
          expect(record.car_alarm_state).to eq 'disarmed'
        end

        it 'prefixes the event predicate methods' do
          expect(record).to be_can_car_alarm_arm
        end

        it 'prefixes the state predicate methods' do
          expect(record).to be_car_alarm_disarmed
        end

        it 'prefixes the bang methods' do
          record.car_alarm_arm!

          expect(record.car_alarm_state).to eq 'armed'
        end

        it 'prefixes the invoke method' do
          record.car_alarm_invoke :arm

          expect(record.car_alarm_state).to eq 'armed'
        end
      end

      context 'when the state has a guard clause' do
        let(:context) { Data.define(:locked) }

        temporary_model 'DoorStateMachine', super_class: Machine do
          state :closed, initial: true do
            event :open, to: :open, if: ->(door) { !door.locked }
          end

          state :open do
            event :close, to: :closed
          end
        end

        temporary_model 'ModelWithStateMachine', super_class: nil do
          include ActiveModel::Model
          include ActiveModel::Attributes
          include described_module[DoorStateMachine]

          attribute :state
          attribute :locked, default: false

          def initialize(attributes = {})
            super(state: DoorStateMachine.initial, **attributes)
          end
        end

        it 'uses the record as the context' do
          record = ModelWithStateMachine.new(locked: true)

          expect { record.invoke :open }
            .to raise_error TransitionHalted,
              'failed to invoke open from closed'
        end
      end

      describe 'event predicate methods' do
        let(:record) { ModelWithStateMachine.new }

        they 'are defined for each event' do
          AlarmStateMachine.events.each do |event|
            expect(record).to respond_to(:"can_#{event}?")
          end
        end

        they 'return true when the event is valid in the current state' do
          {
            disarmed: {
              arm: be_truthy,
              disarm: be_falsey,
              trigger: be_falsey,
              silence: be_falsey,
            },
            armed: {
              arm: be_falsey,
              disarm: be_truthy,
              trigger: be_truthy,
              silence: be_falsey,
            },
            triggered: {
              arm: be_falsey,
              disarm: be_falsey,
              trigger: be_falsey,
              silence: be_truthy,
            },
          }.each do |(state, events)|
            record = ModelWithStateMachine.new(state:)

            events.each do |event, be_expected_value|
              expect(record.send(:"can_#{event}?")).to be_expected_value
            end
          end
        end
      end

      describe 'state predicate methods' do
        let(:record) { ModelWithStateMachine.new }

        they 'are defined for each state' do
          AlarmStateMachine.states.each_key do |state|
            expect(record).to respond_to(:"#{state}?")
          end
        end

        they 'return true when in that state' do
          AlarmStateMachine.states.each_key do |state|
            record = ModelWithStateMachine.new(state:)

            expect(record.send(:"#{state}?")).to be_truthy
          end
        end

        they 'return false when not in that state' do
          states = AlarmStateMachine.states.keys

          states.each do |state|
            other_states = states - [state]
            record = ModelWithStateMachine.new(state:)

            values = other_states.collect { |other_state|
              record.send(:"#{other_state}?")
            }

            expect(values).to all(be_falsey)
          end
        end
      end

      describe 'bang methods' do
        they 'are defined for each event' do
          record = ModelWithStateMachine.new

          AlarmStateMachine.events.each do |event|
            expect(record).to respond_to(:"#{event}!")
          end
        end

        they 'invoke the event' do
          record = ModelWithStateMachine.new

          allow(record).to receive(:invoke)

          AlarmStateMachine.events.each do |event|
            record.send :"#{event}!"

            expect(record)
              .to have_received(:invoke)
              .with(event, context: record)
          end
        end

        they 'persist the changes' do
          record = ModelWithStateMachine.new

          allow(record).to receive(:invoke) # ignore transition errors
          allow(record).to receive(:save!)

          AlarmStateMachine.events.each do |event|
            record.send :"#{event}!"
          end

          expect(record)
            .to have_received(:save!)
            .exactly(AlarmStateMachine.events.length).times
        end

        they 'invokes the event with the given context' do
          record = ModelWithStateMachine.new
          context = double

          allow(record).to receive(:invoke)

          AlarmStateMachine.events.each do |event|
            record.send(:"#{event}!", context:)

            expect(record)
              .to have_received(:invoke)
              .with(event, context:)
          end
        end
      end
    end
  end
end
