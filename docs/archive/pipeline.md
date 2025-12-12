# Pipeline

## Discovery

Purpose: Frame the Bet

Goal: Turn opportunities into shaped and validated strategic bets with clear scope and value.

### Capture

##### Purpose

Capture is the intake of raw signals that will eventually feed analysis, modeling, and product decisions. Without systematic capture, every later stage is guesswork.

##### Scope

-   **Sources:** user interactions, sensors, APIs, logs, surveys, annotations.
-   **Granularity:** what to capture and at what frequency.
-   **Coverage:** ensure completeness across systems and user journeys.
-   **Fidelity:** store signals in raw form before transformation.

##### Key Activities

1.  Define capture goals.
2.  Instrument systems (logging hooks, telemetry, connectors).
3.  Establish pipeline (destination, partitioning, retention).
4.  Document provenance (source, method, frequency).
5.  Ensure ethics & compliance.

##### Deliverables

-   **Data Inventory**
-   **Logging Plan**
-   **Provenance Notes**
-   **Initial Storage Layout**

##### Capture Readiness Checklist

-   [ ] Critical signals identified
-   [ ] Schemas consistent (IDs, timestamps, units)
-   [ ] Context captured (user, session, device, environment)
-   [ ] Raw data stored before transformation
-   [ ] Privacy/compliance documented
-   [ ] Retention policy defined

##### Debt Smells

-   Silent logging failures (no alerts)
-   Mixed timestamp formats
-   Only storing aggregates, no raw
-   Non-unique IDs
-   Capture tied only to UI, not backend ground truth

#### Blank Template

`discovery/capture/data-inventory.md`

```markdown
# Data Inventory: <Project>

Owner: <name>  
Date: <YYYY-MM-DD>  
Version: v1  
Tags: artifact:capture

## Sources
- <System or Sensor>: description, frequency, format, owner
- <API/Log>: description, fields, sampling, retention

## Schema Summary
- timestamp: <format, timezone>
- ids: <user_id, session_id, device_id>
- fields: <field list with units>

## Storage Layout
- Path: <storage path>
- Partitioning: <daily/hourly/by-client>
- Retention: <X days/months/years>

## Provenance
- Source: <system/device>
- Ingest method: <ETL/SDK/API>
- Known caveats: <limitations, missing data>

## Risks & Constraints
- Privacy/compliance issues
- Reliability concerns
- Dependencies
```

#### Example (SonoSensei)

`discovery/capture/data-inventory-sonosensei.md`

```markdown
# Data Inventory: SonoSensei

Owner: Wendy (Data Ops)  
Date: 2025-09-01  
Version: v1  
Tags: artifact:capture, initiative:sonosensei

## Sources
- Ultrasound video frames (30 fps via Butterfly SDK)
- Probe telemetry (depth, gain, orientation)
- Session metadata (operator_id, session_id, breed, weight)
- Manual annotations (expert: good_view / bad_view)

## Schema Summary
- timestamp: ISO8601 UTC
- session_id: UUID
- operator_id: UUID
- depth: float (cm)
- gain: float (dB)
- orientation: enum (left/right/neutral)
- annotation: enum (good/bad/none)

## Storage Layout
- Path: clients/{client}/products/sonosensei/data/raw/{session_id}/
- Partitioning: daily, by clinic, by session
- Retention: raw indefinite, derived 2 years

## Provenance
- Source: Butterfly iQ+ Vet probe  
- Ingest method: Butterfly SDK v0.9 → Azure Blob staging  
- Known caveats: telemetry may be missing in older SDK versions

## Risks & Constraints
- Consent forms required per clinic
- Annotation backlog may delay labeling
- Operator IDs must map to validated registry
```

### Measurement

##### Purpose

Measurement transforms **raw captured signals** into structured, quantifiable data that can be compared, analyzed, and modeled. It provides the foundation for observation and hypothesis by defining consistent metrics, features, and schemas.

##### Scope

-   **Frame-level**: pixel values, telemetry, low-level features.
-   **Clip-level**: aggregated statistics, quality measures, duration.
-   **Session-level**: operator metrics, case summaries.
-   **Dataset-level**: distribution of sessions, devices, demographics.

##### Key Activities

1.  **Schema definition** — define fields, units, and datatypes.
2.  **Feature extraction** — derive structured features from raw signals.
3.  **Label alignment** — connect annotations to frames/clips.
4.  **Metric computation** — define business/clinical/product metrics.
5.  **Quality checks** — ensure data validity, consistency, and completeness.

##### Deliverables

-   **Feature Catalog** (list of features/metrics with definitions).
-   **Measurement Schema** (formal table layouts).
-   **Derived Dataset** (processed, structured data).
-   **Quality Report** (missing values, anomalies, distributions).

##### Measurement Readiness Checklist

-   [ ] Features are consistently defined and documented
-   [ ] Labels aligned with correct records
-   [ ] Metrics computed with clear formulas and units
-   [ ] Derived datasets versioned and reproducible
-   [ ] Data quality validated (profile, anomalies logged)

##### Debt Smells

-   Features defined inconsistently across teams
-   Ad hoc scripts with no central schema
-   Annotation-frame mismatches
-   Derived metrics not versioned
-   No anomaly or outlier tracking

#### Blank Template

`discovery/measurement/feature-catalog.md`

```markdown
# Feature Catalog: <Project>

Owner: <name>  
Date: <YYYY-MM-DD>  
Version: v1  
Tags: artifact:measurement

## Frame-Level Features
- <feature_name>: <datatype> (<unit>) — <description>

## Clip-Level Features
- <feature_name>: <datatype> (<unit>) — <description>

## Session-Level Metrics
- <metric_name>: <datatype> (<unit>) — <description>

## Dataset-Level Metrics
- <metric_name>: <datatype> — <description>

## Notes
- <assumptions, caveats, versioning info>
```

#### Example (SonoSensei)

`discovery/measurement/feature-catalog-sonosensei.md`

```markdown
# Feature Catalog: SonoSensei

Owner: Donny (Data Science)  
Date: 2025-09-02  
Version: v1  
Tags: artifact:measurement, initiative:sonosensei

## Frame-Level Features
- brightness_mean: float (0–255) — average pixel intensity
- snr_estimate: float (dB) — signal-to-noise ratio
- probe_depth: float (cm) — probe depth setting
- probe_gain: float (dB) — probe gain setting
- orientation: enum (left/right/neutral) — probe orientation

## Clip-Level Features
- clip_length: float (s) — duration of clip
- good_frame_pct: float (0–1) — % frames labeled good view
- motion_stability: float (normalized) — frame-to-frame jitter measure

## Session-Level Metrics
- attempts: int — number of clips recorded for target view
- time_to_good_view: float (s) — time from session start to first good frame
- operator_success_rate: float (0–1) — proportion of good views per session

## Dataset-Level Metrics
- breed_distribution: histogram — distribution of dog breeds scanned
- weight_distribution: histogram — distribution of weights in kg
- annotation_coverage: float (% frames labeled)
- device_versions: counts of device/software version usage

## Notes
- All LA:Ao measurements standardized to early diastole
- Derived datasets stored as `sonosensei_measure_v1`
- Outliers flagged in separate quality report
```

### Observation

##### Purpose

Observation is the act of **examining measured data** to identify patterns, anomalies, and signals of interest. It’s about seeing “what is” before interpreting “why.” Observation turns metrics into insights and sets up intuition, theory, and hypotheses.

##### Scope

-   **Frame-level:** anomalies, distributional shifts.
-   **Clip-level:** success/failure ratios, stability, variance.
-   **Session-level:** operator trends, learning curves, consistency.
-   **Dataset-level:** skews by device, demographic, or environment.

##### Key Activities

1.  **Exploratory analysis** — plot distributions, check correlations.
2.  **Pattern recognition** — note recurring behaviors or trends.
3.  **Temporal analysis** — examine sequences, progression, or learning curves.
4.  **Anomaly detection** — flag outliers or missing behaviors.
5.  **Record observations** — keep logs of *what was seen* without over-interpreting.

##### Deliverables

-   **Observation Log** (systematic record of findings).
-   **Visualizations** (plots, charts, dashboards).
-   **Anomaly Report** (outliers or red flags).

##### Observation Readiness Checklist

-   [ ] Quality score validated (≥ threshold).
-   [ ] Distributions plotted for key features.
-   [ ] Anomalies flagged and documented.
-   [ ] Session and dataset-level summaries generated.
-   [ ] Observations linked to dataset version.

##### Debt Smells

-   Observations made without quality validation.
-   Findings stored only in slides or chats (not versioned).
-   No reproducibility (missing dataset version link).
-   Mixing interpretation with observation (blurring intuition too early).

#### Blank Template

`discovery/observation/observation-log.md`

```markdown
# Observation Log: <Project>

Owner: <name>  
Date: <YYYY-MM-DD>  
Dataset Version: <dataset_id or version>  
Tags: artifact:observation

## Frame-Level
- <finding about raw frame features or distributions>

## Clip-Level
- <finding about clip-level metrics, e.g. stability, length>

## Session-Level
- <finding about operator/session behavior or performance>

## Dataset-Level
- <finding about dataset-wide skews or coverage>

## Anomalies
- <list flagged anomalies, IDs, or sessions>

## Next Steps
- <planned follow-up actions or checks>
```

#### Example (SonoSensei)

`discovery/observation/observation-log-sonosensei.md`

```markdown
# Observation Log: SonoSensei

Owner: Brant (Analyst)  
Date: 2025-09-02  
Dataset Version: sonosensei_measure_v1  
Tags: artifact:observation, initiative:sonosensei

## Frame-Level
- Brightness distribution shows bimodal pattern → likely due to auto-gain settings.
- ~3% of frames have snr_estimate < 10 dB → potential probe contact issue.

## Clip-Level
- Median clip length = 12s.
- Median good_frame_pct = 42%.
- 15 clips contain 0% good frames → potential exclusion candidates.

## Session-Level
- Operator A improved time_to_good_view from 28s → 12s over 10 sessions.
- Operator B remains stable at ~20s (no improvement).
- Breeds >30kg show higher failure rate.

## Dataset-Level
- Clinic X accounts for 55% of sessions → dataset skew risk.
- Device v1.9 sessions have higher jitter than v2.0.

## Anomalies
- Session 1234: LA:Ao ratio = 3.2 (likely labeling error).
- 2 sessions missing operator metadata.

## Next Steps
- Validate anomalous sessions with experts.
- Explore hypotheses about breed weight and difficulty.
```

### Intuition

##### Purpose

Intuition is the stage where human judgment, domain knowledge, and product sense are layered onto raw observations. It’s not about proving or testing yet — it’s about **sense-making**. Intuition bridges what we *see* (Observation) with what we might *believe or try* (Theory, Thesis, Hypothesis).

##### Scope

-   Interpret patterns through domain expertise.
-   Generate plausible explanations for anomalies or trends.
-   Highlight areas of interest for deeper investigation.
-   Propose early product hunches or design ideas.

##### Key Activities

1.  **Overlay domain expertise** — involve clinicians, operators, or subject-matter experts.
2.  **Interpret observations** — “What might explain this?”
3.  **Generate product hunches** — speculative ideas for design, feedback loops, or interventions.
4.  **Separate signal from noise** — document interpretations as hypotheses-in-waiting, not facts.

##### Deliverables

-   **Intuition Notes**: narrative linking observations to potential meaning.
-   **Expert Commentary**: short inputs from domain experts.
-   **Product Hunch List**: speculative features or interventions.

##### Intuition Readiness Checklist

-   [ ] Domain experts reviewed observation data.
-   [ ] Interpretations clearly labeled as speculation, not fact.
-   [ ] Intuition notes trace back to observations.
-   [ ] Observations vs. interpretations clearly separated.

##### Debt Smells

-   Treating intuition as fact (no clear separation).
-   No subject-matter expert input.
-   Intuition not documented (lost in verbal discussions).
-   Over-generalizing from a small or skewed dataset.

#### Blank Template

`discovery/intuition/intuition-notes.md`

```markdown
# Intuition Notes: <Project>

Owner: <name>  
Date: <YYYY-MM-DD>  
Dataset Version: <dataset_id or version>  
Tags: artifact:intuition

## Interpretation of Observations
### <Observation category>
- Observation: <what was seen>
- Intuition: <possible explanation>
- Hunch: <speculative product/experiment idea>

## Product Hunch List
- <short bullet list of speculative features, interventions, or designs>

## Expert Commentary
- <summary of domain expert insights, quotes, or notes>
```

#### Example (SonoSensei)

`discovery/intuition/intuition-notes-sonosensei.md`

```markdown
# Intuition Notes: SonoSensei

Owner: Charles (Product Lead)  
Date: 2025-09-03  
Dataset Version: sonosensei_measure_v1  
Tags: artifact:intuition, initiative:sonosensei

## Interpretation of Observations

### Operator Performance
- Observation: Operator A improved time_to_good_view from 28s → 12s over 10 sessions.
- Intuition: Suggests SonoSensei feedback loop is accelerating skill acquisition.
- Hunch: Add a progress dashboard to reinforce motivation.

### Breed/Weight Effects
- Observation: Dogs >30kg show higher failure rates.
- Intuition: Larger thoracic cavity makes PSAX view acquisition harder.
- Hunch: Add breed/weight-specific training modules.

### Device/Version Effects
- Observation: Device v1.9 shows higher jitter than v2.0.
- Intuition: Hardware differences are affecting signal stability.
- Hunch: Encourage clinics to upgrade or design jitter compensation in the pipeline.

### Annotation Conflicts
- Observation: 3% of clips had conflicting good/bad view labels.
- Intuition: Some PSAX frames are inherently ambiguous.
- Hunch: Introduce an “ambiguous” category for labeling and guidance.

## Product Hunch List
- Operator performance dashboard
- Breed/weight curriculum modules
- Real-time gain/jitter feedback
- Ambiguity-aware training workflow

## Expert Commentary
- Dr. Safian (Vet Cardiologist): “Larger breeds often require repositioning; training should explicitly cover this.”
- Dr. Lee (Echo Educator): “Ambiguity handling is critical — students often lose confidence when feedback is inconsistent.”
```

### Theory

##### Purpose

Theory anchors intuition in **established knowledge, frameworks, or scientific principles**. It ensures that what we think we see is not just a hunch, but is explained (or challenged) by recognized research, standards, or prior work.

##### Scope

-   Scientific principles (e.g., physics, statistics, learning theory).
-   Industry or domain standards (e.g., medical guidelines, ISO standards).
-   Research literature and prior studies.
-   Baseline expectations (human accuracy, clinical thresholds, business norms).

##### Key Activities

1.  **Review literature and standards** — summarize relevant research and formal guidelines.
2.  **Link to observations/intuition** — explain why observed patterns might occur.
3.  **Document baseline metrics** — thresholds, expected ranges, accepted norms.
4.  **Identify contested areas** — where theory disagrees or evidence is mixed.

##### Deliverables

-   **Theory Note**: concise summary of relevant theories/frameworks.
-   **Lit Scan**: curated reference list of supporting sources.
-   **Baseline Metrics Reference**: table of accepted thresholds or norms.

##### Theory Readiness Checklist

-   [ ] At least 3–5 authoritative sources cited.
-   [ ] Baseline metrics documented and referenced.
-   [ ] Observations/intuition linked to established frameworks.
-   [ ] Contested/uncertain areas acknowledged.

##### Debt Smells

-   No citations, only vague “common knowledge.”
-   Cherry-picking literature to confirm biases.
-   Outdated or irrelevant references.
-   No baseline metrics documented.

#### Blank Template

`discovery/theory/theory-note.md`

```markdown
# Theory Note: <Project>

Owner: <name>  
Date: <YYYY-MM-DD>  
Dataset Version: <dataset_id or version>  
Tags: artifact:theory

## Domain Standards
- <summary of established practices or guidelines>

## Scientific Principles
- <summary of relevant theories or models>

## Literature References
- <author, year> — <finding or relevance>
- <author, year> — <finding or relevance>

## Baseline Metrics Reference
- <metric_name>: <value/range> (source)

## Contested Areas
- <noted disagreements or open questions>
```

#### Example (SonoSensei)

`discovery/theory/theory-note-sonosensei.md`

```markdown
# Theory Note: SonoSensei

Owner: Sarah (Clinical Lead)  
Date: 2025-09-03  
Dataset Version: sonosensei_measure_v1  
Tags: artifact:theory, initiative:sonosensei

## Domain Standards
- Right parasternal short-axis (PSAX) at the aortic root is the standard view for canine LA:Ao measurement.
- Measurement should be taken at early diastole for consistency.

## Scientific Principles
- LA:Ao is considered body-size independent and a reliable marker of atrial enlargement.
- Skill acquisition in medical imaging follows a power law of practice — feedback accelerates proficiency.
- In ML pipelines, view classification precedes measurement tasks.

## Literature References
- Marchesotti et al., 2019 — LA:Ao ratio widely used for left atrial size in dogs.
- Kuo et al., 2024 — Most veterinary cardiologists prefer PSAX LA:Ao as standard measurement.
- Gearhart et al., 2022 — Deep learning models effective at echocardiographic view classification.

## Baseline Metrics Reference
- LA:Ao normal: ~1.0–1.5
- LA:Ao dilated: >1.5
- Inter-rater reliability for good/bad views: κ = 0.8–0.9

## Contested Areas
- Reference intervals for LA:Ao may vary slightly by breed and method.
- Some studies suggest alternative normalization approaches (e.g., LA diameter indexed to body weight).
```

### Thesis

##### Purpose

Thesis is the stage where we transform theory and intuition into a **strategic bet**: a guiding proposition about where value lies and how an AI product could create it. Unlike a hypothesis (narrow and testable), the thesis is **broader, directional, and value-focused**.

##### Scope

-   State the overarching proposition that guides the project.
-   Define the opportunity in terms of value (business, clinical, user).
-   Anchor in theory but extend toward product strategy.
-   Provide focus for downstream use cases and hypotheses.

##### Key Activities

1.  **Formulate strategic proposition** — e.g., “If we solve X with AI, it creates Y value.”
2.  **Frame the opportunity** — describe user, client, or market impact.
3.  **Link to theory** — cite scientific or industry knowledge supporting the thesis.
4.  **Articulate assumptions** — what must be true for this thesis to hold.

##### Deliverables

-   **Thesis Statement**: concise articulation of the strategic bet.
-   **Opportunity Note**: context, drivers, expected impact.
-   **Assumption Log**: explicit list of conditions and risks.

##### Thesis Readiness Checklist

-   [ ] Thesis stated in one or two sentences.
-   [ ] Opportunity and value clearly defined.
-   [ ] Linked back to theory and observation.
-   [ ] Key assumptions documented.
-   [ ] Risks acknowledged.

##### Debt Smells

-   Thesis too vague (“AI will improve outcomes”).
-   No clear value proposition.
-   Not linked to any theory or prior observation.
-   Hidden assumptions not documented.

#### Blank Template

`discovery/thesis/thesis-note.md`

```markdown
# Thesis Note: <Project>

Owner: <name>  
Date: <YYYY-MM-DD>  
Dataset Version: <dataset_id or version>  
Tags: artifact:thesis

## Thesis Statement
- <Concise statement of the strategic bet>

## Opportunity
- <Who benefits, what problem is solved, what value is created>

## Supporting Theory
- <Relevant standards, principles, or findings>

## Assumptions
- <Explicit list of what must hold true for thesis to be valid>

## Risks
- <Known uncertainties or external dependencies>
```

#### Example (SonoSensei)

`discovery/thesis/thesis-note-sonosensei.md`

```markdown
# Thesis Note: SonoSensei

Owner: Charles (Product Lead)  
Date: 2025-09-04  
Dataset Version: sonosensei_measure_v1  
Tags: artifact:thesis, initiative:sonosensei

## Thesis Statement
- If SonoSensei can guide novice veterinarians to reliably acquire and interpret PSAX LA:Ao views, then clinics can improve diagnostic accuracy, operator confidence, and training efficiency.

## Opportunity
- Veterinary clinics struggle with training operators to acquire consistent echo views.
- AI-guided training could reduce onboarding time, improve diagnostic reliability, and expand access to quality care.
- Potential value: faster training cycles, fewer misdiagnoses, stronger client trust.

## Supporting Theory
- LA:Ao is a body-size–independent marker of left atrial enlargement (Marchesotti et al., 2019).
- Skill acquisition improves with real-time feedback and deliberate practice.
- ML models can classify views and assess quality reliably (Gearhart et al., 2022).

## Assumptions
- Clinics will adopt AI guidance tools if they save time and reduce errors.
- Operators can change behavior based on feedback prompts.
- LA:Ao remains the standard measurement in veterinary cardiology.
- Annotated datasets are sufficient to train robust models.

## Risks
- Resistance from experienced operators who prefer traditional methods.
- Variability across breeds or devices may limit generalizability.
- Regulatory or liability considerations in medical guidance tools.
```

### Use Case

##### Purpose

The Use Case translates the **thesis** into a **specific job-to-be-done** for a user, client, or operator. It frames the AI product’s purpose in concrete, practical terms and defines the scenario where value is delivered.

##### Scope

-   Define *who* the user is.
-   Define *what* the user needs to achieve.
-   Define *why* it matters (value or outcome).
-   Keep it narrow enough to design/test, but broad enough to capture meaningful value.

##### Key Activities

1.  **Identify target user** — role, context, and needs.
2.  **Describe scenario** — how they interact with the system.
3.  **Define job-to-be-done** — functional, emotional, or social outcome.
4.  **Connect to value** — business or clinical outcome tied to thesis.

##### Deliverables

-   **Use Case Brief**: concise description of user, scenario, and goal.
-   **JTBD Statement**: job-to-be-done written in user language.
-   **Success Criteria**: what success looks like in the scenario.

##### Use Case Readiness Checklist

-   [ ] Clear user role identified.
-   [ ] Scenario grounded in real-world workflow.
-   [ ] Job-to-be-done stated in user-centered language.
-   [ ] Success criteria defined and measurable.
-   [ ] Ties back directly to thesis.

##### Debt Smells

-   Use case too vague (“help users with AI”).
-   No explicit user role defined.
-   No measurable success criteria.
-   Not clearly linked to thesis or value proposition.

#### Blank Template

`discovery/use-case/use-case-brief.md`

```markdown
# Use Case Brief: <Project>

Owner: <name>  
Date: <YYYY-MM-DD>  
Tags: artifact:use-case

## User
- <Role, background, context>

## Scenario
- <Describe when and how the user engages with the system>

## Job-To-Be-Done
- <“When I…, I want to…, so I can…” statement>

## Success Criteria
- <Specific measurable outcomes for this use case>

## Link to Thesis
- <How this use case supports the strategic bet>
```

#### Example (SonoSensei)

`discovery/use-case/use-case-brief-sonosensei.md`

```markdown
# Use Case Brief: SonoSensei

Owner: Charles (Product Lead)  
Date: 2025-09-04  
Tags: artifact:use-case, initiative:sonosensei

## User
- Veterinary intern with limited ultrasound experience.
- Working in a general practice clinic with minimal cardiology support.

## Scenario
- The intern is scanning a dog suspected of having mitral valve disease.
- They struggle to acquire a clear PSAX LA:Ao view and need real-time guidance.

## Job-To-Be-Done
- When I am scanning a patient and cannot find the correct PSAX view,
- I want SonoSensei to guide me toward adjusting probe depth, angle, and gain,
- So I can capture a high-quality view, measure LA:Ao accurately, and complete the exam confidently.

## Success Criteria
- Intern successfully acquires correct PSAX view within 2 attempts.
- LA:Ao measurement accuracy within ±0.1 of expert measurement.
- Operator confidence scores improve by 30% after guided sessions.

## Link to Thesis
- Supports thesis that guiding novices to acquire reliable PSAX LA:Ao views improves diagnostic accuracy, training efficiency, and clinic value.
```

### Hypothesis

##### Purpose

The Hypothesis narrows a thesis into a **specific, testable claim** that can be validated or falsified. It defines the measurable relationship between input, intervention, and outcome. Hypotheses are the backbone of experiments and evaluation.

##### Scope

-   State a focused, testable proposition.
-   Identify variables (independent, dependent).
-   Define measurable success criteria.
-   Connect directly to a use case and thesis.

##### Key Activities

1.  **Formulate testable statements** — “If X, then Y, as measured by Z.”
2.  **Define measurement plan** — specify metrics and thresholds.
3.  **Identify baseline comparison** — what performance or process you are improving on.
4.  **Document assumptions** — what conditions must hold for the hypothesis to be valid.

##### Deliverables

-   **Hypothesis Statement** (clear, testable).
-   **Metrics & Thresholds** (evaluation plan).
-   **Baseline Reference** (point of comparison).
-   **Assumption Log** (risks and conditions).

##### Hypothesis Readiness Checklist

-   [ ] Statement is falsifiable and measurable.
-   [ ] Metrics and thresholds defined.
-   [ ] Baseline comparison documented.
-   [ ] Assumptions and risks listed.
-   [ ] Links to use case and thesis are explicit.

##### Debt Smells

-   Hypotheses stated too broadly (“AI will improve training”).
-   No measurable outcome defined.
-   No baseline for comparison.
-   Assumptions left implicit.

#### Blank Template

`discovery/hypothesis/hypothesis-note.md`

```markdown
# Hypothesis Note: <Project>

Owner: <name>  
Date: <YYYY-MM-DD>  
Tags: artifact:hypothesis

## Hypothesis Statement
- If <intervention>, then <outcome>, as measured by <metric>.

## Metrics & Thresholds
- <metric_name>: <target value or range>

## Baseline
- <existing performance or process measure to compare against>

## Assumptions
- <conditions that must hold for hypothesis to be valid>

## Risks
- <factors that could invalidate the test>
```

#### Example (SonoSensei)

`discovery/hypothesis/hypothesis-note-sonosensei.md`

```markdown
# Hypothesis Note: SonoSensei

Owner: Donny (Data Science)  
Date: 2025-09-05  
Tags: artifact:hypothesis, initiative:sonosensei

## Hypothesis Statement
- If SonoSensei provides real-time guidance on probe depth, gain, and orientation,
- Then novice operators will acquire a correct PSAX LA:Ao view within 2 attempts,
- As measured by expert-validated annotations.

## Metrics & Thresholds
- Success rate: ≥80% correct PSAX views within 2 attempts.
- Time-to-good-view: ≤15s median.
- Measurement accuracy: LA:Ao within ±0.1 of expert measurement.

## Baseline
- Current novice success rate: ~40% without guidance.
- Median time-to-good-view: ~30s without guidance.

## Assumptions
- Operators follow on-screen feedback.
- Experts provide consistent labeling of “correct view.”
- Device telemetry (depth/gain/orientation) is reliable.

## Risks
- Feedback may be too complex or distracting in real time.
- Dataset bias (e.g., mostly small breeds) may skew outcomes.
- Operator fatigue or clinic constraints could confound results.
```

### Baseline

##### Purpose

Baseline defines the **current state of performance** against which hypotheses and experiments will be compared. It provides the “as-is” benchmark so that improvements are measurable and meaningful.

##### Scope

-   Current workflows, processes, or systems (manual or automated).
-   Existing performance metrics (accuracy, speed, cost, satisfaction, etc.).
-   Historical data or reference standards.
-   Human or industry benchmarks.

##### Key Activities

1.  **Collect reference data** — summarize past performance.
2.  **Compute baseline metrics** — measure accuracy, time, cost, etc.
3.  **Document variability** — note variance across users, sessions, or cohorts.
4.  **Define evaluation window** — ensure baseline matches context of experiment.

##### Deliverables

-   **Baseline Report**: summary of current performance.
-   **Benchmark Metrics Table**: key values with sources.
-   **Context Notes**: conditions, cohorts, and caveats.

##### Baseline Readiness Checklist

-   [ ] Metrics computed from reliable data.
-   [ ] Variability across cohorts documented.
-   [ ] Timeframe and context clearly stated.
-   [ ] Sources and provenance logged.
-   [ ] Baseline stored as versioned artifact.

##### Debt Smells

-   No baseline documented (“we’ll know improvement when we see it”).
-   Metrics cherry-picked or inconsistently defined.
-   Baseline computed from different context than experiment.
-   Hidden variability (e.g., only averages, no distributions).

#### Blank Template

`discovery/baseline/baseline-report.md`

```markdown
# Baseline Report: <Project>

Owner: <name>  
Date: <YYYY-MM-DD>  
Tags: artifact:baseline

## Context
- <description of current process, system, or workflow>

## Baseline Metrics
- <metric_name>: <value> (units, source, time window)
- <metric_name>: <value> (units, source, time window)

## Variability
- <differences across users, cohorts, devices, etc.>

## Benchmark References
- <human performance, industry standard, or published benchmark>

## Notes
- <assumptions, caveats, known limitations>
```

#### Example (SonoSensei)

`discovery/baseline/baseline-report-sonosensei.md`

```markdown
# Baseline Report: SonoSensei

Owner: Brant (Analyst)  
Date: 2025-09-06  
Tags: artifact:baseline, initiative:sonosensei

## Context
- Novice veterinary interns scanning dogs for PSAX LA:Ao without AI guidance.
- Sessions captured across 3 clinics, 12 operators, 320 cases.

## Baseline Metrics
- Success rate (correct PSAX within 2 attempts): 42%
- Median time-to-good-view: 30s
- LA:Ao measurement error vs expert: ±0.25
- Annotation coverage: 85% of frames labeled by experts

## Variability
- Operator A improved naturally over time (success rate ↑ to 60%).
- Large breeds (>30kg) showed higher failure rate (~35% success).
- Device v1.9 scans showed more jitter than v2.0.

## Benchmark References
- Experienced operators typically achieve 85–90% success within 2 attempts.
- Expert LA:Ao measurement variance: ±0.1

## Notes
- Baseline skewed toward small breeds (60% of dataset).
- Annotation lag may affect accuracy for 15% of sessions.
```

### Experiment Design

##### Purpose

Experiment (Design) is where we **plan the test** of a hypothesis before implementation. It specifies how we will evaluate, what data we’ll use, what methods we’ll try, and how success will be judged. This is **design, not execution** — the blueprint for experimentation.

##### Scope

-   Define experiment objective and link to hypothesis.
-   Specify datasets (train, validation, test).
-   Choose evaluation metrics and thresholds.
-   Plan methods, model families, or algorithms to explore.
-   Define constraints (time, cost, compute, data).
-   Include risk, ethics, and compliance considerations.

##### Key Activities

1.  **Write experiment plan** — what will be tested, how, and why.
2.  **Define evaluation design** — metrics, baselines, thresholds.
3.  **Specify data splits** — ensure reproducibility and fairness.
4.  **Identify constraints** — compute budget, runtime, availability.
5.  **Plan documentation** — how results will be logged and reviewed.

##### Deliverables

-   **Experiment Design Doc** (structured plan).
-   **Evaluation Rubric** (metrics and thresholds).
-   **Data Split Specification** (versioned datasets).
-   **Risk & Ethics Notes** (bias, compliance, user impact).

##### Experiment Readiness Checklist

-   [ ] Hypothesis is clearly linked.
-   [ ] Metrics and thresholds are defined.
-   [ ] Baseline comparison documented.
-   [ ] Dataset splits specified and versioned.
-   [ ] Risks and ethical issues noted.
-   [ ] Success/failure conditions are explicit.

##### Debt Smells

-   Jumping straight into coding without design doc.
-   Undefined or moving metrics/thresholds.
-   Using test data in design phase (data leakage).
-   No reproducibility (no dataset versions recorded).
-   Risks not considered.

#### Blank Template

`discovery/experiment/experiment-design.md`

```markdown
# Experiment Design: <Project>

Owner: <name>  
Date: <YYYY-MM-DD>  
Tags: artifact:experiment

## Objective
- <link to hypothesis and describe goal of experiment>

## Datasets
- Train: <dataset_id, version>
- Validation: <dataset_id, version>
- Test: <dataset_id, version>
- Notes: <sampling strategy, exclusions, splits>

## Methods
- <candidate approaches, model families, or algorithms>

## Metrics & Thresholds
- <metric_name>: <target threshold>
- <metric_name>: <target threshold>

## Baseline Comparison
- <baseline values from baseline report>

## Constraints
- <compute, time, budget, data limits>

## Risks & Ethics
- <bias risks, compliance issues, fairness concerns>

## Success Criteria
- <clear pass/fail or go/no-go criteria>
```

#### Example (SonoSensei)

`discovery/experiment/experiment-design-sonosensei.md`

```markdown
# Experiment Design: SonoSensei

Owner: Donny (Data Science)  
Date: 2025-09-07  
Tags: artifact:experiment, initiative:sonosensei

## Objective
- Test whether real-time probe guidance improves novice success rate for PSAX LA:Ao acquisition.
- Linked to Hypothesis: ≥80% correct PSAX views within 2 attempts, ≤15s time-to-good-view.

## Datasets
- Train: sonosensei_train_v1 (annotated clips, 250 sessions)
- Validation: sonosensei_val_v1 (50 sessions, stratified by breed/weight)
- Test: sonosensei_test_v1 (20 sessions, held-out, unseen operators)
- Notes: Splits stratified by operator and breed to ensure generalization.

## Methods
- CNN-based view classification model (baseline).
- Transformer-based video model for quality scoring.
- Feedback overlay prototype to guide probe adjustments.

## Metrics & Thresholds
- Success rate: ≥80% (correct PSAX views within 2 attempts).
- Time-to-good-view: ≤15s median.
- Measurement accuracy: LA:Ao within ±0.1 of expert.
- Latency: ≤100ms per frame.

## Baseline Comparison
- Success rate baseline: 42%
- Median time-to-good-view baseline: 30s
- Measurement error baseline: ±0.25

## Constraints
- Run on Butterfly iQ+ Vet device (mobile hardware).
- Inference budget ≤500 MB model, ≤1.5 W power draw.
- Experiment window: 3 weeks.

## Risks & Ethics
- Risk of overfitting to small breeds.
- Annotation inconsistencies may affect labels.
- Real-time guidance could distract operators if poorly designed.

## Success Criteria
- Pass if ≥80% success rate and ≤15s time-to-good-view achieved on test set.
- Fail if improvements are not statistically significant over baseline.
```

### Discovery Review

##### Purpose

Discovery Review is a **formal checkpoint** before experiments or implementations begin. Its purpose is to ensure that the discovery was rigorous and the shaped bet is validated and sound. It acts as a safeguard against wasted effort, technical debt, and avoidable failure.

##### Scope

-   Validate experiment design for rigor and feasibility.
-   Confirm data quality, splits, and baselines are reliable.
-   Check that metrics, thresholds, and success criteria are explicit.
-   Assess risks, ethics, and compliance.
-   Identify and document technical debt or design smells.

##### Key Activities

1.  **Review experiment design doc** — verify clarity, completeness, and alignment.
2.  **Validate data readiness** — dataset versions, splits, and quality score.
3.  **Check metrics and thresholds** — confirm they are well-defined and achievable.
4.  **Assess risks** — fairness, bias, compliance, or ethical concerns.
5.  **Run debt smell scan** — identify design weaknesses likely to cause fragility later.
6.  **Decision** — go / adjust / no-go.

##### Deliverables

-   **Design Review Notes**: summary of findings and decisions.
-   **Debt Smell Report**: identified risks and remediation suggestions.
-   **Decision Record**: go / adjust / no-go, with rationale.

##### Design Review Readiness Checklist

-   [ ] Experiment design doc completed.
-   [ ] Dataset versions and splits documented.
-   [ ] Baseline metrics available.
-   [ ] Evaluation rubric defined.
-   [ ] Risks and ethics section completed.
-   [ ] Debt smell scan conducted.

##### Debt Smells

-   Undefined or moving success criteria.
-   Ambiguous or overlapping datasets.
-   Metrics chosen for convenience, not relevance.
-   Ignoring bias, compliance, or safety risks.
-   Overly complex design without justification.

#### Blank Template

`discovery/workflow:design-review/workflow:design-review-notes.md`

```markdown
# Design Review Notes: <Project>

Owner: <name>  
Date: <YYYY-MM-DD>  
Tags: artifact:design-review

## Summary
- <overview of review session and scope>

## Findings
- <strengths, weaknesses, gaps>

## Debt Smells
- <list of risks, technical debt indicators, fragilities>

## Decision
- Go / Adjust / No-Go
- Rationale: <explanation for decision>

## Action Items
- <list of required changes or follow-ups>
```

#### Example (SonoSensei)

`discovery/workflow:design-review/workflow:design-review-notes-sonosensei.md`

```markdown
# Design Review Notes: SonoSensei

Owner: Sarah (Clinical Lead)  
Date: 2025-09-08  
Tags: artifact:design-review, initiative:sonosensei

## Summary
- Reviewed experiment design for real-time PSAX LA:Ao guidance model.
- Scope: validate datasets, metrics, and risks before implementation.

## Findings
- Dataset splits stratified and versioned correctly.
- Metrics align with clinical standards (LA:Ao ±0.1, κ ≥0.8).
- Baseline values well-documented.
- Success criteria clear and measurable.

## Debt Smells
- Annotation inconsistencies across clinics could skew results.
- Breed imbalance (60% small breeds) may reduce generalizability.
- Latency constraint (<100ms) not stress-tested on older devices.

## Decision
- Adjust: proceed with design, but require additional data balancing step and annotation audit before execution.
- Rationale: risks manageable with mitigation.

## Action Items
- [ ] Conduct inter-rater reliability audit of annotations.
- [ ] Augment dataset with larger breed cases before final training.
- [ ] Run latency profiling on device v1.9 hardware.
```

## Inception

Purpose: Design the Bet

Goal: Convert a shaped and validated bet into a designed solution with specs, research, and acceptance criteria.

### Product Requirement

##### Purpose

Product Requirement translates strategic intent (thesis, use case, hypothesis) into a **formal specification** of what the system must deliver. It captures the functional and non-functional requirements that guide design and implementation.

##### Scope

-   Define what the system must do (functional).
-   Define quality and constraints (non-functional).
-   Capture acceptance criteria.
-   Ensure traceability back to thesis, use case, and hypothesis.

##### Key Activities

1.  **Gather inputs** — thesis, use case briefs, hypotheses, design review notes.
2.  **Write requirement statement(s)** — clear, testable, and unambiguous.
3.  **Specify acceptance criteria** — measurable conditions of satisfaction.
4.  **Include non-functional constraints** — latency, reliability, compliance, cost.
5.  **Review for clarity** — avoid vague or open-ended wording.

##### Deliverables

-   **Product Requirement Document (PRD)** or entry in requirement backlog.
-   **Acceptance Criteria Table**.
-   **Traceability Links** (to thesis, use case, hypothesis).

##### Product Requirement Readiness Checklist

-   [ ] Requirement stated clearly and unambiguously.
-   [ ] Functional and non-functional requirements documented.
-   [ ] Acceptance criteria testable and measurable.
-   [ ] Linked back to upstream artifacts (use case, hypothesis).
-   [ ] Reviewed and approved by stakeholders.

##### Debt Smells

-   Vague requirements (“should be fast”).
-   No acceptance criteria (hard to test).
-   Non-functional requirements ignored.
-   No link back to thesis or use case.

#### Blank Template

`requirements/product-requirement.md`

```markdown
# Product Requirement: <Project / Feature>

Owner: <name>  
Date: <YYYY-MM-DD>  
Tags: artifact:requirement

## Requirement Statement
- <clear, testable description of requirement>

## Functional Requirements
- <list of what system must do>

## Non-Functional Requirements
- <performance, reliability, compliance, cost constraints>

## Acceptance Criteria
- <metric_name>: <threshold>
- <metric_name>: <threshold>

## Traceability
- Linked Thesis: <reference>
- Linked Use Case: <reference>
- Linked Hypothesis: <reference>
```

#### Example (SonoSensei)

`requirements/product-requirement-sonosensei.md`

```markdown
# Product Requirement: SonoSensei PSAX Guidance

Owner: Charles (Product Lead)  
Date: 2025-09-09  
Tags: artifact:requirement, initiative:sonosensei

## Requirement Statement
- The system must provide real-time guidance to help novice operators acquire correct PSAX LA:Ao views within 2 attempts.

## Functional Requirements
- Detect probe orientation, depth, and gain from device telemetry.
- Classify ultrasound frames as correct/incorrect view in real time.
- Provide actionable feedback (e.g., “tilt left,” “reduce depth”) on-screen.
- Confirm view validity when correct PSAX view is achieved.

## Non-Functional Requirements
- Inference latency: ≤100 ms per frame.
- Model size: ≤500 MB for mobile deployment.
- Reliability: ≥95% uptime in clinical use.
- Compliance: Adhere to veterinary device data-handling standards.

## Acceptance Criteria
- Success rate: ≥80% correct views within 2 attempts.
- Time-to-good-view: ≤15s median.
- Measurement accuracy: LA:Ao within ±0.1 of expert baseline.

## Traceability
- Linked Thesis: [Thesis Note: SonoSensei](../thesis/thesis-note-sonosensei.md)
- Linked Use Case: [Use Case Brief: SonoSensei](../use-case/use-case-brief-sonosensei.md)
- Linked Hypothesis: [Hypothesis Note: SonoSensei](../hypothesis/hypothesis-note-sonosensei.md)
```

### Feature Request

##### Purpose

Feature Request translates product requirements into **backlog-ready items** that can be designed, estimated, and implemented by engineering, design, and product teams. It breaks down requirements into **specific product features** aligned with user needs.

##### Scope

-   Describe the feature in user-facing terms.
-   Provide context (linked requirement, use case, thesis).
-   Include rationale (why it matters, what value it adds).
-   Define acceptance criteria and dependencies.
-   Serve as a unit of work for design/engineering teams.

##### Key Activities

1.  **Write feature description** — what the feature is and what it enables.
2.  **Add user story / JTBD framing** — connect to real workflows.
3.  **Define acceptance criteria** — testable and measurable.
4.  **Identify dependencies** — other features, services, or data assets.
5.  **Link to requirement** — traceability from product requirement to feature.

##### Deliverables

-   **Feature Request Ticket** (in backlog or repo).
-   **Acceptance Criteria**.
-   **Traceability Links**.

##### Feature Request Readiness Checklist

-   [ ] Feature clearly described in user terms.
-   [ ] Acceptance criteria testable.
-   [ ] Dependencies identified.
-   [ ] Traceability links back to requirement.
-   [ ] Value proposition clear.

##### Debt Smells

-   Feature vague (“make scanning better”).
-   No acceptance criteria (can’t verify completion).
-   Missing dependency documentation.
-   Feature not tied to product requirement.

#### Blank Template

`features/feature-request.md`

```markdown
# Feature Request: <Feature Name>

Owner: <name>  
Date: <YYYY-MM-DD>  
Tags: artifact:feature-request

## Description
- <brief explanation of feature and value>

## User Story / JTBD
- As a <user role>, I want <capability>, so that <value/outcome>.

## Acceptance Criteria
- <criterion 1>
- <criterion 2>
- <criterion 3>

## Dependencies
- <list of related features, data, or services>

## Traceability
- Linked Requirement: <reference>
- Linked Use Case: <reference>
- Linked Thesis: <reference>
```

#### Example (SonoSensei)

`features/feature-request-sonosensei.md`

```markdown
# Feature Request: Real-Time Probe Guidance Overlay

Owner: Charles (Product Lead)  
Date: 2025-09-10  
Tags: artifact:feature-request, initiative:sonosensei

## Description
- A real-time overlay that provides actionable guidance (e.g., “tilt left,” “reduce depth”) to help operators acquire a correct PSAX LA:Ao view within 2 attempts.

## User Story / JTBD
- As a novice veterinary intern,
- I want SonoSensei to show me how to adjust the probe in real time,
- So that I can quickly and confidently capture the correct PSAX view.

## Acceptance Criteria
- Overlay displays guidance within ≤100 ms latency.
- Guidance accuracy ≥80% when compared to expert judgment.
- System confirms “correct view” when LA:Ao view achieved.
- Feedback is clear and does not obstruct clinical image.

## Dependencies
- Frame classification model (view detection).
- Probe telemetry capture.
- Feedback rendering pipeline.

## Traceability
- Linked Requirement: [Product Requirement: SonoSensei PSAX Guidance](../requirements/product-requirement-sonosensei.md)
- Linked Use Case: [Use Case Brief: SonoSensei](../use-case/use-case-brief-sonosensei.md)
- Linked Thesis: [Thesis Note: SonoSensei](../thesis/thesis-note-sonosensei.md)
```

### Decision

##### Purpose

The Decision stage captures a **concise, versioned record** of choices made after design review. It follows the ADR pattern: **context → decision → consequences**. This format makes decisions easy to track, revisit, and justify over time.

##### Scope

-   Lock in the outcome (Go, Adjust, or No-Go).
-   Provide context (why this decision was needed).
-   State the decision clearly.
-   Document consequences, trade-offs, and follow-up actions.

##### Deliverables

-   **Decision ADR**: short, numbered, and stored in repo.

##### Decision Readiness Checklist

-   [ ] Context is clear and documented.
-   [ ] Outcome stated in one line.
-   [ ] Consequences and trade-offs identified.
-   [ ] Follow-ups assigned with owners.
-   [ ] Stored as a permanent artifact (not ephemeral).

##### Debt Smells

-   Decisions not recorded in repo.
-   No explanation of context (hard to understand later).
-   Consequences not listed (blind spots).
-   Action items uncoupled from owners.

#### Blank Template

`decisions/adr-XXXX-decision.md`

```markdown
# ADR-XXXX: <Short Title>

Date: <YYYY-MM-DD>  
Status: Accepted | Superseded | Deprecated  
Tags: artifact:decision

## Context
- <why this decision was needed, what problem it addresses>

## Decision
- <concise statement of the outcome: Go / Adjust / No-Go + rationale>

## Consequences
- <positive impacts, expected outcomes>
- <negative impacts, risks, trade-offs>

## Action Items
- <list of follow-ups, mitigations, owners>

## References
- <links to design review notes, experiment design, baseline reports>
```

#### Example (SonoSensei)

`decisions/adr-0007-decision-sonosensei.md`

```markdown
# ADR-0007: Proceed with Adjustments for PSAX Guidance Experiment

Date: 2025-09-08  
Status: Accepted  
Tags: artifact:decision, initiative:sonosensei

## Context
- Design review identified strong overall experiment design.
- Two risks could compromise validity:
  1. Annotation inconsistency across clinics.
  2. Dataset imbalance (60% small breeds, underrepresentation of large breeds).

## Decision
- Proceed with experiment **only after adjustments**:
  - Run annotation reliability audit.
  - Collect additional large-breed cases.
  - Profile latency on device v1.9 hardware.

## Consequences
- Positive: Maintains rigor, improves generalizability, ensures clinical credibility.
- Negative: Delays experiment start by ~2 weeks, requires additional data collection effort.
- Trade-off: Sacrifices speed for validity.

## Action Items
- [ ] Annotation audit (Sarah, due 2025-09-15).
- [ ] Large-breed data collection (Brant, due 2025-09-20).
- [ ] Device v1.9 latency profiling (Donny, due 2025-09-18).

## References
- [Design Review Notes: SonoSensei](../workflow:design-review/workflow:design-review-notes-sonosensei.md)
- [Experiment Design: SonoSensei](../experiment/experiment-design-sonosensei.md)
- [Baseline Report: SonoSensei](../baseline/baseline-report-sonosensei.md)
```

### Inception Review

## Elaboration

Purpose: Plan Bet Execution

Goal: Break down requirements into features and tasks, implement, and prepare for delivery.

### Task

##### Purpose

Task is the **atomic unit of execution**. It translates a feature request into concrete, assignable work items for engineering, design, or data science. Tasks are flexible in scope (small enough to complete, big enough to deliver value) and are where implementation happens.

##### Scope

-   Define a single unit of work.
-   Assign ownership and accountability.
-   Specify inputs, outputs, and completion definition.
-   Maintain traceability to feature, requirement, and higher-level artifacts.

##### Key Activities

1.  **Break down feature request** into discrete tasks.
2.  **Write task description** — what to do, expected outcome.
3.  **Define inputs/outputs** — files, models, data, or code produced.
4.  **Set acceptance criteria** — when is the task done?
5.  **Assign ownership** — responsible operator/agent.

##### Deliverables

-   **Task Specification**: description, inputs/outputs, acceptance criteria.
-   **Linkages**: to feature request, requirement, use case, etc.
-   **Status Tracking**: part of workflow (New → In Progress → Review → Done).

##### Task Readiness Checklist

-   [ ] Task is clear and unambiguous.
-   [ ] Acceptance criteria defined.
-   [ ] Inputs and outputs specified.
-   [ ] Owner/operator assigned.
-   [ ] Linked to upstream feature/requirement.

##### Debt Smells

-   Tasks too large (unclear scope).
-   No acceptance criteria (done is subjective).
-   No owner/operator assigned.
-   Disconnected from upstream artifacts.
-   Work logged outside of system (no traceability).

#### Blank Template

`tasks/task.md`

```markdown
# Task: <Task Title>

ID: <unique identifier>  
Owner: <name or role>  
Date: <YYYY-MM-DD>  
Tags: artifact:task

## Description
- <clear explanation of the task to be completed>

## Inputs
- <files, models, data, context required>

## Outputs
- <expected deliverables, artifacts, or changes produced>

## Acceptance Criteria
- <criterion 1>
- <criterion 2>
- <criterion 3>

## Dependencies
- <other tasks, features, or requirements>

## Traceability
- Linked Feature: <reference>
- Linked Requirement: <reference>
- Linked Use Case: <reference>
```

#### Example (SonoSensei)

`tasks/task-sonosensei-psax-classifier.md`

```markdown
# Task: Implement PSAX View Classifier Model

ID: TSK-001  
Owner: Donny (Data Scientist)  
Date: 2025-09-11  
Tags: artifact:task, initiative:sonosensei

## Description
- Build and train a machine learning model to classify ultrasound frames as correct or incorrect PSAX LA:Ao views in real time.

## Inputs
- sonosensei_train_v1 dataset (250 annotated sessions)
- sonosensei_val_v1 dataset (50 sessions, stratified)
- Annotation guidelines (good vs bad view criteria)

## Outputs
- Trained classification model (v1)
- Model evaluation report with metrics
- Exported model artifact suitable for mobile deployment

## Acceptance Criteria
- Classification accuracy ≥85% on validation set.
- Latency ≤100 ms per frame on test device.
- Model packaged with versioned artifact name.

## Dependencies
- Baseline dataset ingestion pipeline.
- Annotation audit completion.

## Traceability
- Linked Feature: [Feature Request: Real-Time Probe Guidance Overlay](../features/feature-request-sonosensei.md)
- Linked Requirement: [Product Requirement: SonoSensei PSAX Guidance](../requirements/product-requirement-sonosensei.md)
- Linked Use Case: [Use Case Brief: SonoSensei](../use-case/use-case-brief-sonosensei.md)
```

✅ Tasks are where strategy becomes **execution** — precise, trackable, and done-or-not-done.
