typedef UnauthorizedCallback = Future<void> Function();

/// Set from [MoimdayApp] bootstrap so [ApiClient] can clear session on 401.
UnauthorizedCallback? globalUnauthorizedHandler;
