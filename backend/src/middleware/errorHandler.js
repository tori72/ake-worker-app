// src/middleware/errorHandler.js
// Centralised error handler middleware

/**
 * Wraps async route handlers and forwards errors to the error handler.
 * Usage: router.get('/path', asyncHandler(async (req, res) => { ... }))
 */
const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

/**
 * Global Express error handler — must be registered last.
 */
const errorHandler = (err, req, res, next) => {
  console.error(`[ErrorHandler] ${req.method} ${req.path}:`, err);

  const status = err.status || err.statusCode || 500;
  const message = err.message || 'Internal Server Error';

  res.status(status).json({
    success: false,
    error: message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};

/**
 * 404 handler — register after all routes.
 */
const notFoundHandler = (req, res) => {
  res.status(404).json({
    success: false,
    error: `Route not found: ${req.method} ${req.originalUrl}`,
  });
};

module.exports = { asyncHandler, errorHandler, notFoundHandler };
