/**
 * Simple role-based access control middleware
 * Usage: protect(['admin', 'manager'])
 */

function protect(allowedRoles = []) {
  return (req, res, next) => {
    // In a real app, you'd verify a JWT token or session
    // For now, we expect user info in headers (for demonstration)
    const userId = req.headers['x-user-id'];
    const userRole = req.headers['x-user-role'];

    if (!userId || !userRole) {
      // If no auth headers, allow request (implement proper auth in production)
      return next();
    }

    if (allowedRoles.length === 0 || allowedRoles.includes(userRole)) {
      req.user = { id: userId, role: userRole };
      return next();
    }

    return res.status(403).json({ error: 'Access denied. Insufficient permissions.' });
  };
}

/**
 * Log user IP address helper
 */
function getUserIP(req) {
  return req.headers['x-forwarded-for'] || req.connection.remoteAddress || req.ip;
}

module.exports = { protect, getUserIP };
