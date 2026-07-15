module StateMachine
  def self.[](state_machine, **)
    Kintide::StateMachine::Bridge[state_machine, **]
  end
end
