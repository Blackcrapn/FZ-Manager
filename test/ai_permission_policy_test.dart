import 'package:flutter_test/flutter_test.dart';
import 'package:fz_manager/ai_permission_policy.dart';

void main() {
  group('AI permission policy', () {
    test('denies every action while AI is disabled', () {
      for (final action in AiFileAction.values) {
        expect(
          canAiPerform(
            aiEnabled: false,
            destructiveActionsAllowed: true,
            action: action,
          ),
          isFalse,
        );
      }
    });

    test('allows non-destructive actions when AI is enabled', () {
      for (final action in [AiFileAction.read, AiFileAction.organize]) {
        expect(
          canAiPerform(
            aiEnabled: true,
            destructiveActionsAllowed: false,
            action: action,
          ),
          isTrue,
        );
      }
    });

    test('requires the separate destructive permission for deletion', () {
      expect(
        canAiPerform(
          aiEnabled: true,
          destructiveActionsAllowed: false,
          action: AiFileAction.delete,
        ),
        isFalse,
      );
      expect(
        canAiPerform(
          aiEnabled: true,
          destructiveActionsAllowed: true,
          action: AiFileAction.delete,
        ),
        isTrue,
      );
    });
  });
}
