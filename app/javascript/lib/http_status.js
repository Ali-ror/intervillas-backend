// https://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml
// Last Update 2022-06-08

// 1xx: Informational - Request received, continuing process
// 2xx: Success - The action was successfully received, understood, and accepted
// 3xx: Redirection - Further action must be taken in order to complete the request
// 4xx: Client Error - The request contains bad syntax or cannot be fulfilled
// 5xx: Server Error - The server failed to fulfill an apparently valid request

export const
      StatusContinue = 100,
      StatusSwitchingProtocols = 101,
      StatusProcessing = 102,
      StatusEarlyHints = 103,
      // 104-199 Unassigned
      StatusOK = 200,
      StatusCreated = 201,
      StatusAccepted = 202,
      StatusNonAuthoritativeInformation = 203,
      StatusNoContent = 204,
      StatusResetContent = 205,
      StatusPartialContent = 206,
      StatusMultiStatus = 207,
      StatusAlreadyReported = 208,
      // 209-225 Unassigned
      StatusIMUsed = 226,
      // 227-299 Unassigned
      StatusMultipleChoices = 300,
      StatusMovedPermanently = 301,
      StatusFound = 302,
      StatusSeeOther = 303,
      StatusNotModified = 304,
      StatusUseProxy = 305,
      // 306 (Unused)
      StatusTemporaryRedirect = 307,
      StatusPermanentRedirect = 308,
      // 309-399 Unassigned
      StatusBadRequest = 400,
      StatusUnauthorized = 401,
      StatusPaymentRequired = 402,
      StatusForbidden = 403,
      StatusNotFound = 404,
      StatusMethodNotAllowed = 405,
      StatusNotAcceptable = 406,
      StatusProxyAuthenticationRequired = 407,
      StatusRequestTimeout = 408,
      StatusConflict = 409,
      StatusGone = 410,
      StatusLengthRequired = 411,
      StatusPreconditionFailed = 412,
      StatusContentTooLarge = 413,
      StatusURITooLong = 414,
      StatusUnsupportedMediaType = 415,
      StatusRangeNotSatisfiable = 416,
      StatusExpectationFailed = 417,
      // 418 (Unused)
      // 419-420 Unassigned
      StatusMisdirectedRequest = 421,
      StatusUnprocessableContent = 422,
      StatusLocked = 423,
      StatusFailedDependency = 424,
      StatusTooEarly = 425,
      StatusUpgradeRequired = 426,
      // 427 Unassigned
      StatusPreconditionRequired = 428,
      StatusTooManyRequests = 429,
      // 430 Unassigned
      StatusRequestHeaderFieldsTooLarge = 431,
      // 432-450 Unassigned
      StatusUnavailableForLegalReasons = 451,
      // 452-499 Unassigned
      StatusInternalServerError = 500,
      StatusNotImplemented = 501,
      StatusBadGateway = 502,
      StatusServiceUnavailable = 503,
      StatusGatewayTimeout = 504,
      StatusHTTPVersionNotSupported = 505,
      StatusVariantAlsoNegotiates = 506,
      StatusInsufficientStorage = 507,
      StatusLoopDetected = 508,
      // 509 Unassigned
      StatusNotExtended = 510, // (OBSOLETED)
      StatusNetworkAuthenticationRequired = 511
      // 512-599 Unassigned
