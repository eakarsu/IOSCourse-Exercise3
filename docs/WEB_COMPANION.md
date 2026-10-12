# Math coach web companion

The existing `runtime/` service is a separate local web companion. It does not change the native iOS application's offline arithmetic, UserDefaults state, or native privacy disclosure. It uses the configured companion administrator/session database and sends a question to OpenRouter only when an authenticated user chooses **Generate with OpenRouter**.

**AI exercise coach** opens the single native coaching feature. Three examples fill its complete question field. Answers appear as headings, explanations, lists, and structured tables; ordinary Copy and Download actions export readable report text. Saved reports open in a centered dialog. **Edit** reuses the saved question for a new answer; **Delete** removes only the authenticated user's saved coaching report; **Cancel** closes the dialog without writing.

**Cancel request** aborts pending provider work and prevents a late answer from appearing or being saved after the server observes cancellation. A report already committed before cancellation remains in history. This companion's coaching reports are ordinary user-owned records; the native app has no remote records or accounts.

The companion retains its existing configuration and provisioning requirements. Native Xcode/simulator/signing and App Store gates remain documented in `RELEASE.md`. No production-release or native simulator validation is implied by the companion's fixture checks.
