/// Never present backend simulation as an actual reconstruction result.
void requireRealExecution(Object? response) {
  if (response is! Map<String, dynamic>) {
    throw const FormatException('Expected a real reconstruction job response.');
  }
  final job = response['job'] is Map<String, dynamic>
      ? response['job'] as Map<String, dynamic>
      : response;
  if (job['execution_mode'] != 'real') {
    throw const FormatException(
      'Only verified real reconstruction is allowed.',
    );
  }
}
