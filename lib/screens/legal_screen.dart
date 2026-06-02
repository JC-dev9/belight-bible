import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ecrã genérico para exibir documentos legais (Política de Privacidade, Termos de Serviço).
class LegalScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Markdown(
        data: content,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        styleSheet: MarkdownStyleSheet(
          h1: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyMedium?.color,
          ),
          h2: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyMedium?.color,
          ),
          h3: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyMedium?.color,
          ),
          p: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: theme.textTheme.bodyMedium?.color,
          ),
          tableHead: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyMedium?.color,
          ),
          tableBody: TextStyle(
            fontSize: 13,
            color: theme.textTheme.bodyMedium?.color,
          ),
          tableBorder: TableBorder.all(
            color: theme.dividerColor,
            width: 1,
          ),
          blockquoteDecoration: BoxDecoration(
            color: isDark ? Colors.yellow.shade900.withValues(alpha: 0.2) : Colors.yellow.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: Colors.yellow.shade700, width: 4),
            ),
          ),
          code: TextStyle(
            backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
            fontFamily: 'monospace',
            fontSize: 13,
          ),
          codeblockDecoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          horizontalRuleDecoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: theme.dividerColor, width: 1),
            ),
          ),
        ),
        onTapLink: (text, href, title) async {
          if (href != null) {
            final uri = Uri.tryParse(href);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        },
      ),
    );
  }
}

/// Textos dos documentos legais
class LegalContent {
  static const String privacyPolicy = '''
# Política de Privacidade — BeLight Bible

**Última atualização:** 6 de maio de 2025

## 1. Introdução

Bem-vindo ao **BeLight Bible**. A sua privacidade é importante para nós. Esta Política de Privacidade explica como Juan Loza recolhe, utiliza e protege os dados pessoais dos utilizadores da aplicação BeLight Bible.

Ao utilizar a Aplicação, aceita as práticas descritas nesta Política de Privacidade.

---

## 2. Dados Recolhidos

### 2.1 Dados que nos fornece diretamente
- **Endereço de email** — utilizado para criar e gerir a sua conta.
- **Nome completo** (opcional) — utilizado para personalizar o seu perfil.

### 2.2 Dados gerados pela utilização da app
- **Destaques de versículos** — versículos que assinala para destacar.
- **Notas pessoais** — anotações que escreve sobre passagens bíblicas.
- **Progresso de leitura** — capítulo e versículo, sequência de dias de leitura.
- **Planos de leitura** — planos em que se inscreveu e o progresso.
- **Devocionais guardados** — devocionais que marcou para guardar.

### 2.3 Dados técnicos (não pessoais)
- Preferências locais (tema, idioma) — guardadas apenas no dispositivo.
- Notificações locais — agendadas no dispositivo, sem envio de dados.

---

## 3. Como Utilizamos os Seus Dados

Os dados são utilizados exclusivamente para:
- Criar e autenticar a sua conta de utilizador.
- Sincronizar as suas notas, destaques e progresso entre dispositivos.
- Mostrar os seus planos de leitura e estatísticas pessoais.

**Não utilizamos os seus dados para publicidade ou marketing.**

---

## 4. Partilha de Dados

**Não vendemos nem partilhamos os seus dados pessoais com terceiros**, com exceção dos seguintes prestadores essenciais:

| Serviço | Finalidade |
|---------|-----------|
| Supabase | Armazenamento e autenticação |

O Supabase processa dados em conformidade com o RGPD, em servidores na União Europeia.

---

## 5. Segurança

- Toda a comunicação usa HTTPS com encriptação TLS.
- Autenticação gerida por Supabase Auth com tokens JWT.
- Acesso protegido por Row Level Security (RLS) — cada utilizador acede apenas aos seus dados.

---

## 6. Os Seus Direitos (RGPD)

Tem os seguintes direitos:
- **Acesso** — solicitar uma cópia dos seus dados.
- **Retificação** — corrigir os dados no ecrã de perfil.
- **Apagamento** — solicitar eliminação da conta e dados.
- **Portabilidade** — solicitar dados em formato legível.

Para exercer estes direitos: **juanloza.dev@gmail.com**

---

## 7. Dados de Menores

A Aplicação não é dirigida a menores de 13 anos.

---

## 8. Contacto

**Juan Loza**
Email: juanloza.dev@gmail.com
País: Portugal 🇵🇹
''';

  static const String termsOfService = '''
# Termos de Serviço — BeLight Bible

**Última atualização:** 6 de maio de 2025

## 1. Aceitação dos Termos

Ao utilizar o **BeLight Bible**, concorda com estes Termos de Serviço. A Aplicação é desenvolvida por **Juan Loza**, com sede em Portugal.

---

## 2. Descrição do Serviço

O BeLight Bible oferece:
- Leitura da Bíblia em múltiplas traduções (ACF, ARC, NTLH).
- Destaques e notas pessoais em versículos.
- Planos de leitura bíblica com progresso diário.
- Devocionais diários e versículo do dia.
- Sincronização de dados via conta pessoal.

---

## 3. Conta de Utilizador

- É responsável pela confidencialidade das suas credenciais.
- Notifique-nos em caso de acesso não autorizado: juanloza.dev@gmail.com
- Pode solicitar o encerramento da sua conta por email.

---

## 4. Licença de Utilização

Concedemos uma licença **pessoal, não exclusiva e não transferível** para uso pessoal não comercial.

É proibido:
- Copiar, modificar ou vender a Aplicação.
- Realizar engenharia inversa do código.
- Utilizar para fins comerciais sem autorização.

---

## 5. Conteúdo Bíblico

- **ACF** e **ARC** — domínio público.
- **NTLH** — Nova Tradução na Linguagem de Hoje © Sociedade Bíblica do Brasil. Utilizada sem fins comerciais, com atribuição ao titular dos direitos.

---

## 6. Conteúdo do Utilizador

O conteúdo que cria (notas, destaques) é **seu**. Concede-nos apenas licença limitada para o armazenar e sincronizar.

---

## 7. Limitação de Responsabilidade

A Aplicação é fornecida "tal como está". Não somos responsáveis por perda de dados ou interrupções de serviço.

---

## 8. Lei Aplicável

Estes Termos são regidos pela lei portuguesa. Litígios serão submetidos aos tribunais de Portugal.

---

## 9. Contacto

**Juan Loza**
Email: juanloza.dev@gmail.com
País: Portugal 🇵🇹
''';
}
