import 'package:flutter_test/flutter_test.dart';

int levenshtein(String a, String b) {
  final dp = List.generate(
    a.length + 1,
    (_) => List<int>.filled(b.length + 1, 0),
  );
  for (var i = 0; i <= a.length; i++) dp[i][0] = i;
  for (var j = 0; j <= b.length; j++) dp[0][j] = j;
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      dp[i][j] = [
        dp[i - 1][j] + 1,
        dp[i][j - 1] + 1,
        dp[i - 1][j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1),
      ].reduce((x, y) => x < y ? x : y);
    }
  }
  return dp.last.last;
}

void main() {
  test('fuzzy path segment recognizes lokal as local', () {
    expect(levenshtein('lokal', 'local'), 1);
  });
}
