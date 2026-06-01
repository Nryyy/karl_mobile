/// Utilities for document-related operations.

/// Checks if a status name matches any of the provided keywords.
///
/// [statusName] the document status name to check
/// [keywords] list of keywords to match against
/// Returns true if the normalized status name contains any keyword.
bool matchesStatus(String statusName, List<String> keywords) {
  final normalized = statusName.toLowerCase();
  return keywords.any(normalized.contains);
}
