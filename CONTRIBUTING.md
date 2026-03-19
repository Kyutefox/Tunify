# Contributing to Tunify

Contributions are welcome and appreciated. Here's how to get started:

## Getting Started

1. **Fork** the repository and create a feature branch:
   ```bash
   git checkout -b feat/your-feature-name
   ```

2. **Make your changes.** Keep PRs focused — one feature or fix per PR.

3. **Run the analyzer** before opening a PR:
   ```bash
   flutter analyze
   dart run build_runner build --delete-conflicting-outputs
   flutter test
   ```

4. **Open a Pull Request** against `main` with a clear description of what changed and why.

## Guidelines

- Follow existing code style (Dart analysis options are enforced via `flutter_lints`).
- Prefer editing existing files over creating new ones.
- Write self-documenting code; add comments only where the logic is non-obvious.
- Do not commit secrets, API keys, or personal Supabase credentials.

## Supabase Setup

This project requires a Supabase instance. See the [README](README.md#supabase-setup) for setup instructions. Never commit your personal `url` or `anonKey` values.

## Reporting Issues

Please use [GitHub Issues](../../issues) to report bugs or request features. Include:
- Steps to reproduce
- Expected vs. actual behaviour
- Platform and Flutter version (`flutter --version`)
