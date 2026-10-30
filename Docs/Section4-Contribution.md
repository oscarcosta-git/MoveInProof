# Section 4 - Team Contribution & Governance Matrix

## Team

| Name | Student ID | GitHub |
|---|---|---|
| Oscar Costa | 25859366 | [oscarcosta-git](https://github.com/oscarcosta-git) |

This project was completed individually, with no other team members. AI assistance is declared in Section 5.

## Git commit verification

All commits are by Oscar Costa (student ID 25859366). Git author names **SlurpyDevv** and **Oscar Costa** are the same person, using the same email; merge commits from GitHub pull requests appear under the GitHub account **oscarcosta-git**.

| Commit | Date | Message |
|---|---|---|
| 8c65034 | 2026-10-22 | MoveInProof Frontend UI |
| 5669dfa | 2026-10-22 | Frontend UI: all screens from mockups with placeholder data |
| b331af1 | 2026-10-22 | Widgets UI: Tenancy dates widget in small and medium sizes |
| 2bd74a3 | 2026-10-29 | Local storage: save tenancy, rooms, photos and issues on device |
| 5c2342d | 2026-10-29 | Camera: live capture with timestamped photos, flash and tap to focus |
| b076242 | 2026-10-30 | PDF export: condition report with timestamped photos, share and save to Files |
| a6bee99 | 2026-10-30 | Widget data: show the saved tenancy dates via a shared App Group |
| d2ab9e1 | 2026-10-30 | refactor: adopt MVVM with use case and repository layers |
| 166ce23 | 2026-10-30 | test: add unit test target with mock repositories for domain use cases |
| ee35bf8 | 2026-10-30 | feat: support Dynamic Type across the app |
| 51487eb | 2026-10-30 | feat: add app icon and privacy manifests |
| 9891daf | 2026-10-30 | docs: add README |
| 778c9f8 | 2026-10-30 | fix: make damage tagging manual and remove simulated detection |
| c7b6830 | 2026-10-30 | chore: date sample data relative to today |
| 98b74d4 | 2026-10-30 | docs: add App Store screenshots |
| 842e497 | 2026-10-30 | docs: add App Store metadata draft |
| 1f15fe1 | 2026-10-30 | docs: add architecture and data flow diagram |

## Governance

- **Branching:** `main` (release), `develop` (integration) and feature branches (`feature/...`, `feat/...`, `fix/...`, `docs/...`). Work reached `main` only through GitHub pull requests (#1 to #6).
- **Commit style:** Conventional Commits (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`) from the architecture work onward; earlier feature commits predate this.
- **Quality gate before merging:** zero build warnings, all unit tests passing, and a manual check in the iOS Simulator.
- **AI assistance:** declared in Section 5 and the README.
