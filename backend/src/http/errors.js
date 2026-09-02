class ApiError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

function notFound(message) {
  return new ApiError(404, "NOT_FOUND", message);
}

function outsideMelbourne(message) {
  return new ApiError(404, "OUTSIDE_MELBOURNE", message);
}

function badRequest(message) {
  return new ApiError(400, "BAD_REQUEST", message);
}

function projectionUnavailable() {
  return new ApiError(
    503,
    "PROJECTION_UNAVAILABLE",
    "The 2050 projection layer could not be read."
  );
}

function asyncHandler(fn) {
  return (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
}

function errorHandler(err, req, res, next) {
  if (res.headersSent) {
    next(err);
    return;
  }
  if (err instanceof ApiError) {
    res.status(err.status).json({
      error: { code: err.code, message: err.message },
    });
    return;
  }
  console.error(err);
  res.status(500).json({
    error: { code: "INTERNAL", message: "Unexpected error." },
  });
}

module.exports = {
  ApiError,
  notFound,
  outsideMelbourne,
  badRequest,
  projectionUnavailable,
  asyncHandler,
  errorHandler,
};
