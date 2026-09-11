enum AiFileAction { read, organize, delete }

/// Central, fail-closed authorization for AI-initiated file actions.
bool canAiPerform({
  required bool aiEnabled,
  required bool destructiveActionsAllowed,
  required AiFileAction action,
}) {
  if (!aiEnabled) return false;
  if (action == AiFileAction.delete) return destructiveActionsAllowed;
  return true;
}
