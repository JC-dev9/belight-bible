import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _buildLogo(isDark)),
              const SizedBox(height: 20),

              Text(
                'Criar conta',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Preencha os campos abaixo para começar sua jornada.',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.hintColor.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Campo Nome
              _buildTextField(
                controller: _nameController,
                hint: 'Nome',
                icon: Icons.person_outline,
                theme: theme,
              ),
              const SizedBox(height: 16),

              // Campo E-mail
              _buildTextField(
                controller: _emailController,
                hint: 'E-mail',
                icon: Icons.mail_outline,
                theme: theme,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Campo Senha
              _buildTextField(
                controller: _passwordController,
                hint: 'Palavra-passe',
                icon: Icons.lock_outline,
                theme: theme,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: theme.hintColor.withValues(alpha: 0.7),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Campo Confirmar Senha
              _buildTextField(
                controller: _confirmPasswordController,
                hint: 'Confirmar palavra-passe',
                icon: Icons.lock_outline,
                theme: theme,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: theme.hintColor.withValues(alpha: 0.7),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Botão Criar Conta
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = _nameController.text.trim();
                    final email = _emailController.text.trim();
                    final password = _passwordController.text.trim();
                    final confirmPassword = _confirmPasswordController.text
                        .trim();

                    if (password != confirmPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('As palavras-passe não coincidem.'),
                        ),
                      );
                      return;
                    }

                    if (password.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'A palavra-passe deve ter pelo menos 6 caracteres.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      final supabase = Supabase.instance.client;
                      final AuthResponse res = await supabase.auth.signUp(
                        email: email,
                        password: password,
                        data: {'name': name},
                      );

                      final user = res.user;

                      if (user != null) {
                        // Mostra o Dialog de sucesso
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text(
                                'Conta criada com sucesso!',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              content: const Text(
                                'Verifique o seu e-mail para confirmar o cadastro antes de fazer login.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Fecha o dialog
                                    Navigator.pop(
                                      context,
                                    ); // Volta para a tela de login
                                  },
                                  child: const Text(
                                    'OK',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    } on AuthException catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.message)));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ocorreu um erro inesperado.'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Criar Conta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Voltar para Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Já tem uma conta?',
                    style: TextStyle(
                      color: theme.hintColor.withValues(alpha: 0.7),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Entrar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Image.asset(
      'assets/logo.png',
      width: 100,
      height: 100,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.menu_book_outlined,
        size: 56,
        color: Colors.amber,
      ),
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: theme.hintColor.withValues(alpha: 0.7)),
          prefixIcon: Icon(icon, color: theme.hintColor.withValues(alpha: 0.7)),
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
}
