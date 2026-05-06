# BeLight Bible

Uma aplicação de leitura bíblica completa, desenvolvida em Flutter, com sincronização na cloud, planos de leitura personalizados e devocionais diários.

---

## 📖 Descrição

O **BeLight Bible** é uma app de estudo e leitura bíblica que combina o texto sagrado com ferramentas modernas de organização pessoal. Lê a Bíblia, faz anotações, destaca versículos e acompanha o teu progresso de leitura — tudo sincronizado entre dispositivos.

### Funcionalidades principais
- 📚 **3 traduções** — ACF, ARC e NTLH
- 🖊️ **Notas e destaques** por versículo, guardados na cloud
- 📅 **Planos de leitura** — múltiplos planos temáticos com progresso diário
- 🕯️ **Devocionais diários** — reflexão e oração para cada dia
- ✨ **Versículo do dia** — com notificação local personalizável
- 🔍 **Pesquisa** em toda a Bíblia
- 🌙 **Modo escuro** completo
- 🔔 **Notificações locais** configuráveis
- 👤 **Perfil com estatísticas** — dias consecutivos, destaques, notas

---

## 🛠️ Stack Tecnológica

| Tecnologia | Utilização |
|---|---|
| [Flutter](https://flutter.dev) 3.x | Framework UI cross-platform |
| [Supabase](https://supabase.com) | Base de dados, autenticação e cloud sync |
| [Hive](https://pub.dev/packages/hive_flutter) | Armazenamento local (preferências) |
| [Riverpod](https://riverpod.dev) | Gestão de estado |
| [flutter_quill](https://pub.dev/packages/flutter_quill) | Editor de notas com formatação rica |
| [flutter_markdown](https://pub.dev/packages/flutter_markdown) | Renderização de devocionais |
| [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) | Notificações locais |

---

## 🚀 Configuração Local

### Pré-requisitos
- Flutter SDK ≥ 3.9.2
- Conta no [Supabase](https://supabase.com)

### 1. Clonar o repositório
```bash
git clone https://github.com/juanloza/belight-bible.git
cd belight-bible
```

### 2. Instalar dependências
```bash
flutter pub get
```

### 3. Configurar variáveis de ambiente

Copia o ficheiro de exemplo e preenche com as tuas credenciais:
```bash
cp dart_env.json.example dart_env.json
```

Edita `dart_env.json`:
```json
{
  "SUPABASE_URL": "https://<teu-project>.supabase.co",
  "SUPABASE_ANON_KEY": "<tua-anon-key>"
}
```

> ⚠️ O ficheiro `dart_env.json` está no `.gitignore` — nunca o commites.

### 4. Executar a app
```bash
flutter run
```

---

## 🗄️ Schema Supabase

As tabelas necessárias no Supabase são:

```
profiles          — Perfil do utilizador (full_name, avatar_url)
highlights        — Destaques de versículos por utilizador
notes             — Notas por versículo com conteúdo em Quill Delta
reading_progress  — Progresso de leitura e streak diário
daily_verses      — Versículos do dia (365 entradas, day_of_year)
devotionals       — Devocionais diários com publish_date
reading_plans     — Planos de leitura disponíveis
user_reading_plans — Inscrições e progresso dos utilizadores nos planos
saved_devotionals — Devocionais guardados pelo utilizador
```

Todas as tabelas de dados do utilizador têm **Row Level Security (RLS)** ativa.

---

## 📱 Gerar Ícones da App

```bash
flutter pub run flutter_launcher_icons
```

Configuração em `flutter_launcher_icons.yaml` — usa `assets/logo.png` com fundo `#121212`.

---

## 📋 Documentos Legais

- [Política de Privacidade](./PRIVACY_POLICY.md)
- [Termos de Serviço](./TERMS_OF_SERVICE.md)

---

## 📄 Licença

© 2025 Juan Loza. Todos os direitos reservados.

O conteúdo bíblico (ACF, ARC) é de domínio público.
