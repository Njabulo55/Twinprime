-- =================================================================
-- INTENT-TO-GAZE BLUEPRINT: PREDICTIVE CONTROL LOOP
-- =================================================================

namespace IntentToGazeBlueprint

noncomputable section

-- 1. CORE TYPES
axiom R : Type
axiom le : R → R → Prop
axiom lt : R → R → Prop
axiom add : R → R → R
axiom sub : R → R → R
axiom zero : R

axiom Intent : Type
axiom SceneBelief : Type
axiom Fixation : Type
axiom Peripheral : Type
axiom Foveal : Type

structure Observation where
  peripheral : Peripheral
  foveal : Foveal

structure State where
  intent : Intent
  belief : SceneBelief
  last_fixation : Fixation
  time : Nat

-- 2. DYNAMICS AND PREDICTIVE CODING
axiom PresaccadicPrior : State → Fixation → Observation → R
axiom UpdateBelief : SceneBelief → Observation → SceneBelief
axiom UpdateIntent : Intent → Observation → Intent
axiom Observe : State → Fixation → Observation

-- 3. VALUE COMPONENTS
axiom TaskReward : Intent → SceneBelief → R
axiom InformationGain : SceneBelief → Observation → R
axiom SaccadeCost : Fixation → Fixation → R

def StepUtility (s : State) (a : Fixation) (o : Observation) : R :=
  sub (add (TaskReward s.intent (UpdateBelief s.belief o)) (InformationGain s.belief o))
      (SaccadeCost s.last_fixation a)

axiom Expectation : (Observation → R) → (Observation → R) → R

def Objective (s : State) (a : Fixation) : R :=
  Expectation (PresaccadicPrior s a) (fun o => StepUtility s a o)

-- 4. TRACTABLE APPROXIMATION (ONE-STEP LOOKAHEAD)
axiom ArgMax : (Fixation → R) → Fixation

def OneStepLookaheadPolicy (s : State) : Fixation :=
  ArgMax (fun a => Objective s a)

-- 5. INTENT- VS SALIENCY-DRIVEN CRITERIA
axiom SaliencyScore : Peripheral → Fixation → R
axiom IntentScore : Intent → Fixation → R
axiom PeripheralFromState : State → Peripheral

def IntentSaliencyGap (s : State) : R :=
  sub (IntentScore s.intent (OneStepLookaheadPolicy s))
      (SaliencyScore (PeripheralFromState s) (OneStepLookaheadPolicy s))

def IntentDriven (s : State) : Prop :=
  lt zero (IntentSaliencyGap s)

def SaliencyDriven (s : State) : Prop :=
  lt (IntentSaliencyGap s) zero

def NeutralDriven (s : State) : Prop :=
  le zero (IntentSaliencyGap s) ∧ le (IntentSaliencyGap s) zero

-- 6. EXPERIMENT PROTOCOL (KAGGLE-FRIENDLY)
structure Dataset where
  name : String
  sequences : Nat

structure ExperimentConfig where
  dataset : Dataset
  compute_budget : Nat
  horizon : Nat
  policy : State → Fixation

structure Metrics where
  compute_reduction : R
  reaction_time_gain : R
  task_success : R

axiom RunExperiment : ExperimentConfig → Metrics

end IntentToGazeBlueprint
