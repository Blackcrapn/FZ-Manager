# FZ Manager security model

## Trust boundaries

- AI is disabled by default. The current build does not send provider requests or execute AI-proposed actions.
- The tool registry is bounded to named capabilities; arbitrary autonomous code or shell execution is not exposed.
- Delete requires a separate opt-in, tool permission and per-action confirmation. User file deletion is implemented as a move to `.fz_trash`.
- Root is never assumed: only `su -c id` is used for an explicit, time-bounded capability check. No generic Root console exists.
- Provider API keys are encrypted with AES-GCM using a non-exportable Android Keystore key. Keys are never hardcoded or written to project files.
- Android scoped-storage restrictions apply. Broad `MANAGE_EXTERNAL_STORAGE` access is not requested; SAF support remains future work.

## Known limitations

- Audit entries and user preferences are memory-only and disappear when the process exits.
- The provider URL is not yet validated or contacted. A future implementation must require HTTPS by default, block loopback/private-network targets unless explicitly approved, enforce timeouts and response-size limits, redact secrets, and rate-limit retries.
- Cross-volume trash moves can fail atomically because filesystem rename is used; failure must never fall back to permanent deletion.
- Release signing credentials must be injected outside source control. Debug keys must not sign production releases.

## Reporting

Report vulnerabilities privately to the repository maintainers. Do not include real API keys, tokens, personal file paths, or sensitive file contents in reports.
