import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart' show HiveKeys;
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Login com email e senha
  Future<void> _handleEmailLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Preencha todos os campos', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Salvar preferência "Lembrar-me"
        final settingsBox = Hive.box(HiveKeys.settingsBox);
        await settingsBox.put(HiveKeys.rememberMe, _rememberMe);

        _showSnackBar('Login realizado com sucesso!');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on AuthException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      _showSnackBar('Erro inesperado. Tente novamente.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Login social com o provedor OAuth (Google ou Facebook)
  Future<void> _handleOAuthLogin(OAuthProvider provider) async {
    try {
      final providerName = provider == OAuthProvider.google ? 'Google' : 'Facebook';

      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: 'io.supabase.belightapp://login-callback/',
      );

      // O OAuth redireciona o utilizador — a sessão é restaurada ao voltar.
      // O listener no Supabase cuida da navegação.
      // Para web, escutamos as mudanças de auth state:
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedIn && mounted) {
          final settingsBox = Hive.box(HiveKeys.settingsBox);
          settingsBox.put(HiveKeys.rememberMe, _rememberMe);
          Navigator.pushReplacementNamed(context, '/home');
        }
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erro no login social. Tente novamente.', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Center(child: _buildLogo(isDark)),
                const SizedBox(height: 20),

                // Texto de boas-vindas
                Text(
                  'Bem-vindo de volta,',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Descubra escolhas ilimitadas e conveniência\nsem igual.',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.hintColor.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                // Campo de E-Mail
                _buildInputField(
                  controller: _emailController,
                  hint: 'E-mail',
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  theme: theme,
                ),
                const SizedBox(height: 16),

                // Campo de Senha
                _buildInputField(
                  controller: _passwordController,
                  hint: 'Palavra-passe',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  theme: theme,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: theme.hintColor.withValues(alpha: 0.7),
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // "Lembrar-me" e "Esqueceu a palavra-passe?"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() => _rememberMe = value ?? false);
                            },
                            activeColor: Colors.yellow.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lembrar-me',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot-password');
                      },
                      child: Text(
                        'Esqueceu a palavra-passe?',
                        style: TextStyle(
                          color: theme.hintColor.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Botão de Iniciar Sessão
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleEmailLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow.shade700,
                      disabledBackgroundColor: Colors.yellow.shade700.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Iniciar Sessão',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Botão para criar conta
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Criar Conta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Separador "Ou entrar com"
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: theme.dividerColor.withValues(alpha: 0.4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Ou entrar com',
                        style: TextStyle(
                          color: theme.hintColor.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: theme.dividerColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Botões de login social
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(
                      icon: Icons.g_mobiledata,
                      label: 'Google',
                      iconColor: Colors.red,
                      onTap: () => _handleOAuthLogin(OAuthProvider.google),
                      borderColor: theme.dividerColor.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 16),
                    _buildSocialButton(
                      icon: Icons.facebook,
                      label: 'Facebook',
                      iconColor: const Color(0xFF1877F2),
                      onTap: () => _handleOAuthLogin(OAuthProvider.facebook),
                      borderColor: theme.dividerColor.withValues(alpha: 0.4),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Logo adaptado para tema
  Widget _buildLogo(bool isDark) {
    Widget logoImage = Image.asset(
      'assets/logo.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade100,
          child: const Icon(
            Icons.image_not_supported_outlined,
            size: 40,
            color: Colors.grey,
          ),
        );
      },
    );

    if (isDark) {
      logoImage = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          -1, 0, 0, 0, 255,
          0, -1, 0, 0, 255,
          0, 0, -1, 0, 255,
          0, 0, 0, 1, 0,
        ]),
        child: logoImage,
      );
    }

    return Center(
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        clipBehavior: Clip.antiAlias,
        child: logoImage,
      ),
    );
  }

  /// Campo de input reutilizável
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    required ThemeData theme,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: theme.hintColor.withValues(alpha: 0.7),
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: theme.hintColor.withValues(alpha: 0.7),
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // Botão social
  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
    required Color borderColor,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 32, color: iconColor),
      ),
    );
  }
}
