module.exports = function (req, res, next) {
  // Checks if the authenticated user has an 'admin' role
  if (req.user && req.user.role === 'admin') {
    next();
  } else {
    res.status(403).json({ message: 'Access denied. Admin rights required.' });
  }
};