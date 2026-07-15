require 'rails_helper'

module Kintide
  module StateMachine
    RSpec.describe Machine do
      temporary_model 'AlarmStateMachine', super_class: described_class do
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

      describe '.events' do
        it 'returns the event names across all states' do
          expect(AlarmStateMachine.events).to eq %w[arm disarm trigger silence]
        end
      end

      describe '#initialize' do
        it 'sets the initial state' do
          machine = AlarmStateMachine.new

          expect(machine.state).to eq 'disarmed'
        end

        context 'with an initial state' do
          it 'sets the initial state' do
            machine = AlarmStateMachine.new(state: 'triggered')

            expect(machine.state).to eq 'triggered'
          end

          context 'when the initial state is a symbol' do
            it 'sets the initial state' do
              machine = AlarmStateMachine.new(state: :triggered)

              expect(machine.state).to eq 'triggered'
            end
          end
        end

        context 'when no initial state is defined' do
          temporary_model 'AlarmStateMachine', super_class: described_class do
            state :disarmed
            state :armed
            state :triggered
          end

          it 'raises an error' do
            expect { AlarmStateMachine.new }
              .to raise_error UndefinedInitialState
          end
        end
      end

      describe '#can_invoke' do
        temporary_model 'DoorStateMachine', super_class: described_class do
          state :closed, initial: true do
            event :open, to: :open
            event :lock, to: :locked
          end

          state :open do
            event :close, to: :closed
          end

          state :locked
        end

        it 'returns true when the event is valid in the current state' do
          aggregate_failures do
            {
              closed: { open: be_truthy, close: be_falsey },
              open: { open: be_falsey, close: be_truthy },
            }.each do |(state, events)|
              events.each do |(event, be_expected_value)|
                machine = DoorStateMachine.new(state:)

                expect(machine.can_invoke?(event)).to be_expected_value
              end
            end
          end
        end

        context 'when the state has a guard clause' do
          let(:context) { Data.define(:locked) }

          temporary_model 'DoorStateMachine', super_class: described_class do
            state :closed, initial: true do
              event :open, to: :open, if: ->(context) { !context.locked }
            end

            state :open do
              event :close, to: :closed
            end
          end

          it 'returns true when the event is valid in the current state' do
            locked = context.new(locked: true)
            unlocked = context.new(locked: false)

            aggregate_failures do
              {
                locked => be_falsey,
                unlocked => be_truthy,
              }.each do |(context, be_expected_value)|
                machine = DoorStateMachine.new(state: :closed)

                expect(machine.can_invoke?(:open, context:))
                  .to be_expected_value
              end
            end
          end
        end
      end

      describe '#invoke' do
        it 'transitions to the state machine to the next state' do
          aggregate_failures do
            [
              %w[disarmed arm armed],
              %w[armed disarm disarmed],
              %w[armed trigger triggered],
              %w[triggered silence disarmed],
            ].each do |(from, event, to)|
              machine = AlarmStateMachine.new(state: from)

              machine.invoke event

              expect(machine.state).to eq to
            end
          end
        end

        context 'when invoking an event with a symbol' do
          it 'transitions to the state machine to the next state' do
            machine = AlarmStateMachine.new(state: :disarmed)

            machine.invoke :arm

            expect(machine.state).to eq 'armed'
          end
        end

        context 'when invoking an undefined event for the current state' do
          it 'raises an invalid state error' do
            aggregate_failures do
              [
                %i[disarmed disarm],
                %i[disarmed trigger],
                %i[disarmed silence],
                %i[armed arm],
                %i[armed silence],
                %i[triggered trigger],
                %i[triggered arm],
                %i[triggered disarm],
              ].each do |(from, event)|
                machine = AlarmStateMachine.new(state: from)

                expect { machine.invoke event }
                  .to raise_error InvalidEvent,
                    "no event #{event} exists in state #{from}"
              end
            end
          end
        end

        context 'with a terminal state' do
          temporary_model 'DoorStateMachine', super_class: described_class do
            state :closed, initial: true do
              event :open, to: :open
              event :lock, to: :locked
            end

            state :open do
              event :close, to: :closed
            end

            state :locked
          end

          it 'transitions to the state machine to the next state' do
            aggregate_failures do
              [
                %w[closed open open],
                %w[closed lock locked],
                %w[open close closed],
              ].each do |(from, event, to)|
                machine = DoorStateMachine.new(state: from)

                machine.invoke event

                expect(machine.state).to eq to
              end
            end
          end
        end

        context 'when the next state is a callable' do
          let(:context) { Data.define(:name) }

          temporary_model 'DoorStateMachine', super_class: described_class do
            state :closed, initial: true do
              event :open,
                to: ->(context) {
                  context.name == 'Chuck Norris' ?
                    :permanently_open :
                    :open
                }
            end

            state :open do
              event :close, to: :closed
            end

            state :permanently_open
          end

          it 'transitions to the state machine to the next state' do
            chuck_norris = context.new(name: 'Chuck Norris')
            anyone_else = context.new(name: Faker::Name.name)

            aggregate_failures do
              {
                chuck_norris => 'permanently_open',
                anyone_else => 'open',
              }.each do |(context, next_state)|
                machine = DoorStateMachine.new

                machine.invoke(:open, context:)

                expect(machine.state).to eq next_state
              end
            end
          end
        end

        context 'when the state has a guard clause' do
          let(:context) { Data.define(:locked) }

          temporary_model 'DoorStateMachine', super_class: described_class do
            state :closed, initial: true do
              event :open, to: :open, if: ->(context) { !context.locked }
            end

            state :open do
              event :close, to: :closed
            end
          end

          it 'transitions to the state machine to the next state' do
            machine = DoorStateMachine.new

            machine.invoke :open, context: context.new(locked: false)

            expect(machine.state).to eq 'open'
          end

          it 'raises an error if the guard condition fails' do
            machine = DoorStateMachine.new

            expect { machine.invoke :open, context: context.new(locked: true) }
              .to raise_error TransitionHalted,
                'failed to invoke open from closed'
          end
        end
      end
    end
  end
end
