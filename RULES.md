FLUTTER AI CODING RULE SET (PROFESSIONAL & INDUSTRY STANDARD)

1. ARCHITECTURE PRINCIPLES
- Follow Clean Architecture:
  - Presentation (UI)
  - Domain (business logic)
  - Data (API, database)
- Prefer feature-based folder structure
- Apply SOLID principles
- Strict separation of concerns:
  - UI must not contain business logic
  - Business logic must not depend on UI

2. STATE MANAGEMENT
- Use scalable state management:
  - Preferred: Riverpod
  - Alternative: Bloc / Cubit
- Avoid:
  - setState for complex logic
  - global mutable state
- Ensure:
  - Immutable state
  - Clear separation of logic and UI

3. PROJECT STRUCTURE

lib/
 ├── core/
 │    ├── constants/
 │    ├── theme/
 │    ├── utils/
 │    └── errors/
 │
 ├── features/
 │    ├── feature_name/
 │    │    ├── data/
 │    │    ├── domain/
 │    │    └── presentation/
 │
 └── main.dart

- Each feature must be self-contained
- Avoid cross-feature dependencies unless through domain layer

4. NAMING CONVENTIONS
- Classes: PascalCase
- Variables/functions: camelCase
- Files: snake_case.dart
- Use meaningful, descriptive names
- Avoid unnecessary abbreviations

5. UI & WIDGET DESIGN
- Build small, reusable widgets
- One widget = one responsibility
- Use const constructors whenever possible
- Extract widgets to avoid deep nesting
- Follow Material/Cupertino guidelines

6. PERFORMANCE OPTIMIZATION
- Use const widgets to reduce rebuilds
- Minimize unnecessary rebuilds
- Use ListView.builder for large lists
- Lazy load data when possible
- Avoid heavy work on main thread (use isolates)

7. ERROR HANDLING
- Never ignore errors
- Use try-catch for async operations
- Create custom failure classes
- Return typed results (Result/Either pattern)
- Show user-friendly error messages

8. DATA & API LAYER
- Use repository pattern:
  - Abstract in domain
  - Implement in data layer
- Use DTOs mapped to domain entities
- Never expose raw API models to UI
- Handle:
  - timeouts
  - null responses
  - network failures

9. DEPENDENCY INJECTION
- Use DI:
  - Riverpod providers OR get_it
- Avoid manual instantiation inside widgets

10. THEMING & DESIGN SYSTEM
- Centralize:
  - colors
  - typography
  - spacing
- Avoid hardcoded values
- Follow consistent spacing system (e.g., 8px grid)

11. CODE QUALITY
- Use dart format
- Follow flutter_lints
- Keep functions small (< 30 lines)
- Ensure single responsibility
- Avoid duplicate code

12. DOCUMENTATION
- Comment only when necessary
- Explain WHY, not WHAT
- Document public APIs and complex logic

13. TESTING
- Write:
  - Unit tests for business logic
  - Widget tests for UI
- Mock dependencies properly
- Cover critical flows

14. SECURITY
- Never hardcode:
  - API keys
  - secrets
- Use secure storage
- Validate all external inputs

15. GIT & WORKFLOW
- Use clear commit messages:
  - feat: add login feature
  - fix: resolve API timeout
- Keep PRs small
- Ensure code is review-ready

16. AI AGENT RULES
- Always generate complete, runnable code
- Avoid placeholders unless asked
- Follow structure before coding
- Prefer clarity over cleverness
- Keep consistency across files
- Do not mix architectures

GOLDEN RULES (NON-NEGOTIABLE)
- No business logic in UI
- No hardcoded magic values
- No unhandled errors
- No messy widget trees
- No tight coupling