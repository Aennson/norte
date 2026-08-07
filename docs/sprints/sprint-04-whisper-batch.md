# Sprint 04 — Whisper Batch: Audio Recording and Meeting Transcription

**Objective:** the second meeting input flow — record audio in the app, transcribe via `WhisperBatchEngine`, and feed the **same** summarization pipeline from Sprint 03.

**Mandatory references:** `docs/architecture.md` §5.1, §9 · BR-03, BR-07

---

## Entry criteria

- [ ] Sprint 03 DoD complete (summarization pipeline working).
- [ ] `FakeBatchTranscription` available.

## Scope

**In:** `TranscriptionEngine`/`BatchTranscription` ports (interface from §9.1); `WhisperBatchEngine` (file upload, key in secure storage, optional language); audio capture (`record`) with microphone permission, recording indicator (elapsed time, level), pause/resume, configurable limit (default 90 min); `TranscribeMeetingAudio` use case connecting recording → transcription → the Sprint 03 pipeline; progress states in the UI (recording → uploading → transcribing → summarizing).

**Out:** realtime/Scribe transcription (Sprint 05), system audio capture (out of scope for v1.0).

## Sprint validation rules

- The meeting audio file is **temporary**: recorded in the app's temp directory, deleted after successful transcription **or** when the user discards it; never in the documents directory.
- A completed transcript enters the Sprint 03 pipeline **with no duplicated code** — same `SummarizeMeeting` use case, same PII and retention rules (BR-03/BR-07 apply to the generated transcript).
- Microphone permission denied → explanatory screen with a link to system settings; never a crash.
- Upload/transcription failure → the local audio file is **kept** and the user can retry without re-recording.
- Recording interruption (phone call, app backgrounded on mobile) → recording paused and recoverable.

## Tests

#### S04-UT-01 — Flow orchestration
- **What it validates:** transcribe → summarize without duplication.
- **Entry criteria:** `TranscribeMeetingAudio` with `FakeBatchTranscription` (returns a fixed transcript) and a spy `SummarizeMeeting`; fake file.
- **Action:** execute with the daily template.
- **Exit criteria:** `SummarizeMeeting` received exactly the engine's transcript and the chosen template; states emitted in the order uploading → transcribing → summarizing → done.

#### S04-UT-02 — Transcription failure preserves the audio
- **What it validates:** the retry-without-re-recording rule.
- **Entry criteria:** fake programmed for `TranscriptionFailure`; existing fake file.
- **Action:** execute; check the file; re-execute with the fake OK.
- **Exit criteria:** after the failure the file still exists and the error is propagated; the retry works with the same file; after success the file is deleted.

#### S04-UT-03 — Cleanup after success and after discard
- **What it validates:** the temp file's lifecycle.
- **Entry criteria:** recording completed in a fake temp directory.
- **Action:** scenario A: full flow with success; scenario B: user discards before transcribing.
- **Exit criteria:** in both scenarios the file is deleted; no audio file remains in the directory.

#### S04-IT-01 — WhisperBatchEngine: correct request
- **What it validates:** conformance with the transcription API.
- **Entry criteria:** fake HTTP server; small fixture audio file; fake key.
- **Action:** `transcribeFile(audio, language: 'pt')`.
- **Exit criteria:** multipart with the file and the language; auth present; response parsed into a `Transcript` with the fake's text; 401 → `AuthFailure`; 5xx → `TranscriptionFailure`.

#### S04-CT-01 — BatchTranscription contract
- **What it validates:** `WhisperBatchEngine` (fake server) and `FakeBatchTranscription` under the same contract.
- **Entry criteria:** parameterized suite; same fixture file.
- **Action:** `transcribeFile` on each adapter; cases: success, nonexistent file, server error.
- **Exit criteria:** same `Transcript` shape and same `Failure`s on both adapters.

#### S04-GT-01 — Recording screen
- **What it validates:** the recording UI in the design system.
- **Entry criteria:** recording / paused / uploading / transcribing states mocked.
- **Action:** render dark/light.
- **Exit criteria:** stable goldens; timer in the `mono` font; the recording indicator uses `accent`; per-stage progress visible.

#### S04-E2E-01 — Record → transcribe → summarize
- **What it validates:** Pillar 2, flow 2, end to end.
- **Entry criteria:** app with `FakeBatchTranscription` (daily transcript) and `FakeAiEngine` (daily summary); fake audio capture injected (produces a dummy file).
- **Action:** new meeting → "Record audio" → record → stop → confirm transcription → process with the daily template → save.
- **Exit criteria:** summary with the daily's sections on screen; meeting saved; the audio file absent from the file system at the end (verified by assert).

#### S04-E2E-02 — Microphone permission denied
- **What it validates:** the permission UX.
- **Entry criteria:** permission provider overridden to "denied".
- **Action:** try to start recording.
- **Exit criteria:** explanatory screen with an action to open settings; no crash; going back and using the paste flow still works.

## Definition of Done

- [ ] Gates G1–G6 green; domain+application coverage ≥ 90%.
- [ ] All S04-* tests passing.
- [ ] Manual script: a real ~1 min recording on each available platform + a real Whisper transcription (your own key) → evidence in the report.
- [ ] Report `docs/reports/sprint-04-report.md`.
