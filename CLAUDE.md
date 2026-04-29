# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 重要说明

**每次新开始工作时，必须首先读取 `1.md` 文件** 以了解当前项目进度和之前的修改历史。该文件记录了所有重要的变更和当前状态。

## Project Overview

NipaPlay-Reload is a cross-platform video player application built with Flutter. It supports Windows, macOS, Linux, Android, iOS, and Web platforms. The app features a powerful danmaku (弹幕) system, media library integration (Emby, Jellyfin, WebDAV, SMB), and Bangumi sync.

## Communication

**始终使用中文（中文）与项目维护者沟通。**

## Development Commands

```bash
# Static analysis (run before commits) - 只输出 error 信息
flutter analyze

# Run tests
flutter test

# Run single test file
flutter test test/path/to/test_file.dart

# Build for different platforms
flutter build linux
flutter build macos
flutter build windows
flutter build apk
flutter build ios

# Run the app in debug mode
flutter run

# Custom build scripts
./build-arm64.sh        # Linux ARM64 build
./build_and_copy_web.sh # Builds web + copies to assets/web/
```

**Note:** This project uses FVM (Flutter Version Management) with Flutter 3.38.5. If you have FVM installed, prefix commands with `fvm` (e.g., `fvm flutter analyze`).

## 编程规矩（来自 Cursor 规则）

1. 代码必须遵循 SOLID 原则
2. 每个函数只干一件事
3. 所有异常必须处理
4. 变量名要说人话（`data` → `userList`）
5. **禁止自以为是地"优化"掉你认为"不需要"的代码** — 只要存在那就不是不需要，只是你自己没看完全部代码
6. 看到能复用的代码就提醒
7. 给出不同方案，说优缺点
8. 检查代码边界情况

## Architecture Overview

### Core Architecture Pattern

The project follows a **pluggable architecture** with Provider for state management:

```
UI Layer (themes/, pages/) 
    → State Layer (VideoPlayerState, providers/)
    → Abstraction Layer (player_abstraction/, danmaku_abstraction/)
    → Implementation Layer (player adapters, danmaku kernels)
```

### Player Abstraction (`lib/player_abstraction/`)

- **Interface**: `abstract_player.dart` defines `AbstractPlayer` — all player kernels must implement this
- **Adapters**: `mdk_player_adapter.dart`, `media_kit_player_adapter.dart`, `video_player_adapter.dart` wrap specific SDKs
- **Factory**: `player_factory.dart` creates player instances based on `PlayerKernelType` enum from SharedPreferences
- **Adding a new player**: Create adapter → Implement `AbstractPlayer` → Add to `PlayerKernelType` enum → Register in factory → Add UI option in settings

### Danmaku Abstraction (`lib/danmaku_abstraction/`)

- Similar pattern: `DanmakuRenderEngine` enum (CPU/GPU/Canvas)
- `danmaku_kernel_factory.dart` manages kernel selection
- Three implementations: `danmaku_gpu/`, `danmaku_canvas/`, CPU renderer

### Service Layer (`lib/services/`)

Singleton services handle external integrations:
- **Media Server**: `jellyfin_service.dart`, `emby_service.dart` (API clients with auth, library management)
  - Multi-address support via `multi_address_server_service.dart`
  - Transcode management: `jellyfin_transcode_manager.dart`, `emby_transcode_manager.dart`
  - Playback sync: `jellyfin_playback_sync_service.dart`, `emby_playback_sync_service.dart`
- **Danmaku**: `dandanplay_service.dart` (弹弹play API integration), `danmaku_cache_manager.dart`
- **Infrastructure**: `debug_log_service.dart`, `web_server_service.dart` (embedded HTTP server using `shelf`)
- **Platform-specific**: `file_association_service.dart`, `windows_file_association_service.dart`

### State Management

- **Provider pattern** for global state (`lib/providers/`)
  - `ServiceProvider` — centralizes service singletons
  - `WatchHistoryProvider`, `UIThemeProvider`, `JellyfinTranscodeProvider`, etc.
  - All registered in `main.dart` with `MultiProvider`
- Services can extend `ChangeNotifier` (e.g., `ScanService`) for reactive state

### Key Files

- **`lib/main.dart`** — Application entry point. Registers all global `ChangeNotifierProvider`s. Key initialization sequence:
  1. `HttpClientInitializer.install()` — Self-signed cert trust (desktop)
  2. `DebugLogService().initialize()` — Enable logging from startup
  3. Platform-specific: `hotKeyManager.unregisterAll()` (desktop), file association handlers
  4. `PlayerFactory.initialize()` / `DanmakuKernelFactory.initialize()` — Preload settings
  5. Provider setup → `runApp()`

- **`lib/utils/video_player_state.dart`** — The central state coordinator for all playback behavior. This is the "brain" of the playback page.

- **`lib/utils/video_player_state/`** — Part files splitting `VideoPlayerState` by responsibility (initialization, playback_controls, danmaku, subtitles, etc.)

- **`lib/themes/`** — UI implementations organized by theme:
  - `nipaplay/` — Main theme (Material style, for desktop)
  - `cupertino/` — iOS-style theme variant (for mobile, Android defaults to this)
  - `theme_registry.dart` — Theme registration
  - **注意**: Android 默认使用 Cupertino 主题，修改设置页面时需要同时修改两个主题的代码

### Custom Packages

The project includes custom packages in `packages/`:
- `media_kit/`, `media_kit_video/` — Video playback (custom fork from `Shinokawa/media-kit`)
- `danmaku_canvas/` — Danmaku rendering canvas
- `nipaplay_smb2/` — SMB2 protocol support
- `adaptive_platform_ui/` — Platform-adaptive UI utilities

### Embedded Web Server

- Implementation: `web_server_service.dart` using `shelf` + `shelf_static`
- Serves Flutter web build from `assets/web/`
- REST API for browser-to-app communication
- See `docs/WEB_SERVER_IMPLEMENTATION.md` for architecture

## Code Style

- Follow Dart naming conventions: `snake_case` for files, `UpperCamelCase` for classes, `lowerCamelCase` for variables/functions
- Run `flutter analyze` before committing and resolve reported issues
- Keep functions small and focused on a single responsibility
- Prefer `const` where possible
- Add documentation comments (`///`) for public APIs

### File Naming Conventions

- Services: `*_service.dart`
- Providers: `*_provider.dart`
- Models: `*_model.dart`
- Pages: `*_page.dart`
- Platform conditionals: `*_io.dart` (native), `*_web.dart` (web), `*_stub.dart` (unsupported)

## Platform-Specific Notes

Platform-specific implementations use conditional imports:
- `*_io.dart` — Desktop/mobile implementations
- `*_stub.dart` — Stub implementations for unsupported platforms
- `*_web.dart` — Web-specific implementations

Platform checks:
- `kIsWeb` — Check if running on web
- `globals.isDesktop` or `PlatformUtils` — Check if running on desktop
- Conditional imports: `import 'path_provider.dart' if (dart.library.html) 'mock_path_provider.dart';`

## Data Layer

- **Models**: `jellyfin_model.dart`, `emby_model.dart`, `bangumi_model.dart`, `playable_item.dart`
- **Database**: `watch_history_database.dart` (SQLite via `sqflite`/`sqflite_common_ffi` for desktop)
- **Configuration**: Settings stored in `SharedPreferences`

## External API Integration

- **弹弹play**: `dandanplay_service.dart` — danmaku matching & fetching
- **Bangumi**: `bangumi_service.dart` — anime metadata (API at `docs/bangumi番组计划api接口.json`)
- **Jellyfin**: OpenAPI spec at `docs/jellyfin-openapi-stable.json`
- **Emby**: OpenAPI spec at `docs/emby-openapi.json`
- **Update checks**: `update_service.dart` — GitHub releases

## Troubleshooting

### Platform-Specific Compilation
- **Desktop**: Ensure MDK or libmpv libraries present
- **Android**: Check `android/app/src/main/jniLibs/` for native libs
- **iOS/macOS**: CocoaPods dependencies, security bookmarks (`security_bookmark_service.dart`)
- **Web**: Force `VideoPlayerAdapter`, no native players available

### State Sync Issues
- Check provider registration in `main.dart`
- Ensure services use singleton pattern: `static final instance = Service._internal();`
- Verify `notifyListeners()` called after state changes

## Contributing Guidelines

See `CONTRIBUTING_GUIDE/` for comprehensive developer docs:
- `00-Introduction.md` — Project vision, AI-assisted contribution workflow
- `02-Project-Structure.md` — Detailed folder breakdown
- `03-How-To-Contribute.md` — Git workflow (fork → branch → commit → PR)
- `04-Coding-Style.md` — Code conventions
- `08-Adding-a-New-Player-Kernel.md` — Step-by-step adapter pattern guide
- `09-Adding-a-New-Danmaku-Kernel.md` — Danmaku engine integration
