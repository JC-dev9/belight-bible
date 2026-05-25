class AppEnv {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  static void assertConfigured() {
    assert(
      supabaseUrl.isNotEmpty,
      'SUPABASE_URL não definido. Execute com --dart-define-from-file=dart_env.json',
    );
    assert(
      supabaseAnonKey.isNotEmpty,
      'SUPABASE_ANON_KEY não definido. Execute com --dart-define-from-file=dart_env.json',
    );
  }
}
