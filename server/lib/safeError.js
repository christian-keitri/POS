const path = require('path');

/**
 * Returns a safe error message for API responses.
 * In production, internal details are hidden.
 */
function safeErrorMessage(err) {
  if (process.env.NODE_ENV === 'production') {
    return 'Internal server error';
  }
  return err?.message || 'Internal server error';
}

/**
 * Resolves a stored filename to a path under uploadsDir. Returns null if path would escape (e.g. '..').
 */
function safeUploadPath(uploadsDir, storedPath) {
  if (!storedPath || typeof storedPath !== 'string') return null;
  const normalized = path.normalize(storedPath).replace(/^(\.\.(\/|\\|$))+/, '');
  const resolved = path.resolve(uploadsDir, normalized);
  const uploadsResolved = path.resolve(uploadsDir);
  if (!resolved.startsWith(uploadsResolved)) return null;
  return resolved;
}

module.exports = { safeErrorMessage, safeUploadPath };
