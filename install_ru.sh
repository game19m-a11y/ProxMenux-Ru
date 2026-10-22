#!/bin/bash

# ==========================================================
# ProxMenux-Ru - Установщик русской локализации для ProxMenux
# ==========================================================
# Author      : game19m-a11y & contributors
# Upstream    : MacRimi (https://github.com/MacRimi/ProxMenux)
# Repository  : https://github.com/game19m-a11y/ProxMenux-Ru
# License     : (GPL-3.0) (https://github.com/game19m-a11y/ProxMenux-Ru/blob/main/LICENSE)
# Version     : 1.2.6-ru.1
# Last Updated: 22/10/2026
# ==========================================================
# Description:
# Устанавливает, проверяет, обновляет и при необходимости откатывает
# полную русскую локализацию ProxMenux:
#   1) Интерактивного консольного меню (CLI: lang/ru.json, config_menu.sh,
#      utils.sh, install_proxmenux*.sh, активация "language": "ru" в config.json)
#   2) Веб-панели мониторинга ProxMenux Monitor (:8008) — установка готового
#      собранного образа ProxMenux-1.2.6.AppImage с проверкой SHA-256 и
#      атомарным обновлением /usr/local/share/proxmenux/monitor-app/ без
#      необходимости наличия Node.js на сервере Proxmox VE
#   3) Наложения локализации поверх дерева исходного кода MacRimi/ProxMenux
#      (--source-dir <путь>) с опциональной пересборкой (--build-appimage).
# ==========================================================

set -uo pipefail

LOCALE_REPO_URL="https://github.com/game19m-a11y/ProxMenux-Ru.git"
LOCALE_VERSION="1.2.6-ru.1"

BASE_DIR="/usr/local/share/proxmenux"
MONITOR_SERVICE="proxmenux-monitor.service"
MONITOR_PORT=8008

ACTION="install"          # install | verify | status | uninstall
ASSUME_YES=0
INSTALL_CLI=1
INSTALL_MONITOR=1
KEEP_CURRENT_LANG=0
NO_SERVICE=0
JSON_OUTPUT=0
SOURCE_TARGET_DIR=""
BUILD_FROM_SOURCE=0
TEMP_CLONE_DIR=""

# Цвета вывода
RD="\033[01;31m"
GN="\033[1;92m"
YW="\033[1;33m"
BL="\033[36m"
BOLD="\033[1m"
CL="\033[m"

log_info()  { [[ "$JSON_OUTPUT" -eq 1 ]] || echo -e "  ${BL}[INFO]${CL}  $*"; }
log_ok()    { [[ "$JSON_OUTPUT" -eq 1 ]] || echo -e "  ${GN}[ OK ]${CL}  $*"; }
log_warn()  { [[ "$JSON_OUTPUT" -eq 1 ]] || echo -e "  ${YW}[WARN]${CL}  $*"; }
log_error() { echo -e "  ${RD}[ERR ]${CL}  $*" >&2; }

cleanup_temp() {
    if [[ -n "$TEMP_CLONE_DIR" && -d "$TEMP_CLONE_DIR" ]]; then
        rm -rf "$TEMP_CLONE_DIR"
    fi
}
trap cleanup_temp EXIT

show_help() {
    cat <<'EOF'
ProxMenux-Ru — установщик русской локализации для ProxMenux (CLI + Web Monitor)

Использование:
  sudo ./install_ru.sh [параметры]
  bash <(curl -fsSL https://raw.githubusercontent.com/game19m-a11y/ProxMenux-Ru/main/install_ru.sh) [--yes]

Основные режимы:
  (без флагов)             Интерактивная установка локализации CLI + ProxMenux Monitor
  -y, --yes                Неинтерактивный режим (без диалоговых запросов — для скриптов и ИИ-агентов)
  --verify, --status       Проверить целостность установленной русской локализации (код возврата 0 = ОК)
  --json                   Вывести результат --verify / --status в машиночитаемом формате JSON
  --uninstall              Откатить русскую локализацию из резервной копии

Выбор компонентов и путей:
  --cli-only               Установить локализацию только для консольного меню (menu)
  --monitor-only           Установить локализацию только для веб-панели (ProxMenux Monitor)
  --keep-lang              Добавить русский язык, не меняя текущий активный язык в config.json
  --base-dir <путь>        Путь установки ProxMenux (по умолчанию: /usr/local/share/proxmenux)
  --no-service             Не управлять службой systemd proxmenux-monitor.service
  --source-dir <путь>      Наложить переведённые исходники поверх клона/архива MacRimi/ProxMenux
  --build-appimage         При использовании --source-dir также пересобрать AppImage из исходников
  -h, --help               Показать эту справку
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y|--yes)
                ASSUME_YES=1
                shift
                ;;
            --verify|--status)
                ACTION="verify"
                shift
                ;;
            --uninstall|--rollback)
                ACTION="uninstall"
                shift
                ;;
            --json)
                JSON_OUTPUT=1
                shift
                ;;
            --cli-only)
                INSTALL_CLI=1
                INSTALL_MONITOR=0
                shift
                ;;
            --monitor-only)
                INSTALL_CLI=0
                INSTALL_MONITOR=1
                shift
                ;;
            --keep-lang)
                KEEP_CURRENT_LANG=1
                shift
                ;;
            --no-service)
                NO_SERVICE=1
                shift
                ;;
            --base-dir)
                [[ $# -lt 2 ]] && { log_error "Для --base-dir требуется аргумент пути"; exit 2; }
                BASE_DIR="$2"
                shift 2
                ;;
            --source-dir)
                [[ $# -lt 2 ]] && { log_error "Для --source-dir требуется путь к исходникам ProxMenux"; exit 2; }
                SOURCE_TARGET_DIR="$2"
                shift 2
                ;;
            --build-appimage)
                BUILD_FROM_SOURCE=1
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Неизвестный параметр: $1 (используйте --help для справки)"
                exit 2
                ;;
        esac
    done
}

resolve_bundle_root() {
    local script_dir=""
    if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    fi

    if [[ -n "$script_dir" && -f "$script_dir/lang/ru.json" && -f "$script_dir/AppImage/messages/ru/common.json" ]]; then
        BUNDLE_ROOT="$script_dir"
        return 0
    fi

    log_info "Локальные файлы репозитория не найдены рядом со скриптом — клонирование $LOCALE_REPO_URL..."
    if ! command -v git >/dev/null 2>&1; then
        log_error "Пакет git не установлен. Установите его командой: apt-get update && apt-get install -y git"
        exit 1
    fi

    TEMP_CLONE_DIR="$(mktemp -d /tmp/proxmenux-ru.XXXXXX)"
    if ! git clone --depth 1 "$LOCALE_REPO_URL" "$TEMP_CLONE_DIR" >/dev/null 2>&1; then
        log_error "Не удалось клонировать репозиторий $LOCALE_REPO_URL"
        exit 1
    fi
    BUNDLE_ROOT="$TEMP_CLONE_DIR"
    log_ok "Репозиторий локализации загружен во временный каталог."
}

validate_json_file() {
    local file="$1"
    [[ -s "$file" ]] || return 1
    if command -v jq >/dev/null 2>&1; then
        jq empty "$file" >/dev/null 2>&1
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "import json, sys; json.load(open(sys.argv[1], encoding='utf-8'))" "$file" >/dev/null 2>&1
    else
        return 1
    fi
}

find_bundled_appimage() {
    local candidate
    for candidate in "$BUNDLE_ROOT"/AppImage/ProxMenux-*.AppImage; do
        if [[ -f "$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

verify_appimage_sha256() {
    local appimage="$1"
    local sha_file="$BUNDLE_ROOT/AppImage/ProxMenux-Monitor.AppImage.sha256"
    [[ -f "$sha_file" ]] || { log_warn "Файл контрольной суммы $sha_file не найден, пропуск проверки SHA-256."; return 0; }

    local expected actual
    expected="$(grep -Eo '^[a-fA-F0-9]{64}' "$sha_file" | head -n 1 | tr 'A-F' 'a-f')"
    actual="$(sha256sum "$appimage" | awk '{print tolower($1)}')"
    if [[ -z "$expected" || "$expected" != "$actual" ]]; then
        log_error "Несовпадение контрольной суммы SHA-256 для $(basename "$appimage")!"
        log_error "Ожидалось: $expected"
        log_error "Получено : $actual"
        return 1
    fi
    log_ok "Контрольная сумма SHA-256 образа $(basename "$appimage") подтверждена."
    return 0
}

apply_to_source_tree() {
    local dst="$1"
    if [[ ! -d "$dst" ]]; then
        log_error "Целевой каталог исходников не существует: $dst"
        return 1
    fi

    log_info "Наложение файлов русской локализации на исходное дерево: $dst"
    local rel_paths=(
        "LICENSE"
        "lang/en.json"
        "lang/ru.json"
        "scripts/menus/config_menu.sh"
        "scripts/utils.sh"
        "install_proxmenux.sh"
        "install_proxmenux_beta.sh"
        "AppImage/lib/i18n/languages.ts"
        "AppImage/lib/i18n/provider.tsx"
        "AppImage/messages/README.md"
        "AppImage/messages/en/common.json"
        "AppImage/messages/ru/common.json"
        "AppImage/components/notification-settings.tsx"
        "AppImage/components/security.tsx"
        "AppImage/components/system-overview.tsx"
        "AppImage/components/virtual-machines.tsx"
        "AppImage/components/host-backup.tsx"
        ".github/scripts/build_i18n_messages.py"
        ".github/scripts/build_translation_cache.py"
        ".github/scripts/build_web_docs_i18n.py"
        "web/i18n/routing.ts"
        "web/components/language-switcher.tsx"
        "web/messages/en/common.json"
        "web/messages/es/common.json"
        "web/messages/sk/common.json"
        "web/messages/ru/common.json"
    )

    local appimage_src
    if appimage_src="$(find_bundled_appimage)"; then
        rel_paths+=("AppImage/$(basename "$appimage_src")")
        [[ -f "$BUNDLE_ROOT/AppImage/ProxMenux-Monitor.AppImage.sha256" ]] && rel_paths+=("AppImage/ProxMenux-Monitor.AppImage.sha256")
    fi

    local rel
    for rel in "${rel_paths[@]}"; do
        if [[ -f "$BUNDLE_ROOT/$rel" ]]; then
            mkdir -p "$(dirname "$dst/$rel")"
            cp -a "$BUNDLE_ROOT/$rel" "$dst/$rel"
        fi
    done

    log_ok "Все переведённые файлы скопированы в $dst с сохранением структуры каталогов."

    if [[ "$BUILD_FROM_SOURCE" -eq 1 ]]; then
        if ! command -v npm >/dev/null 2>&1; then
            log_error "Для --build-appimage требуется установленный Node.js 20+ и npm."
            return 1
        fi
        log_info "Пересборка веб-приложения AppImage из исходников..."
        if [[ -x "$dst/AppImage/scripts/build_appimage.sh" ]]; then
            (cd "$dst/AppImage" && bash ./scripts/build_appimage.sh) || return 1
            if ls "$dst"/AppImage/dist/ProxMenux-*.AppImage >/dev/null 2>&1; then
                cp -f "$dst"/AppImage/dist/ProxMenux-*.AppImage "$dst/AppImage/"
                (cd "$dst/AppImage" && sha256sum ProxMenux-*.AppImage > ProxMenux-Monitor.AppImage.sha256)
                log_ok "Образ AppImage успешно пересобран из исходников."
            fi
        fi
    fi

    return 0
}

backup_existing_files() {
    local backup_dir="$BASE_DIR/backup-ru-locale"
    mkdir -p "$backup_dir"

    # Сохраняем первоначальные оригиналы только если бэкап ещё не создавался,
    # чтобы повторный запуск install_ru.sh не затирал эталонную точку отката.
    if [[ ! -f "$backup_dir/.backup_initialized" ]]; then
        log_info "Создание точки отката в $backup_dir..."
        [[ -f "$BASE_DIR/config.json" ]] && cp -a "$BASE_DIR/config.json" "$backup_dir/config.json.orig"
        [[ -f "$BASE_DIR/utils.sh" ]] && cp -a "$BASE_DIR/utils.sh" "$backup_dir/utils.sh.orig"
        [[ -f "$BASE_DIR/install_proxmenux.sh" ]] && cp -a "$BASE_DIR/install_proxmenux.sh" "$backup_dir/install_proxmenux.sh.orig"
        [[ -f "$BASE_DIR/install_proxmenux_beta.sh" ]] && cp -a "$BASE_DIR/install_proxmenux_beta.sh" "$backup_dir/install_proxmenux_beta.sh.orig"
        [[ -f "$BASE_DIR/scripts/menus/config_menu.sh" ]] && cp -a "$BASE_DIR/scripts/menus/config_menu.sh" "$backup_dir/config_menu.sh.orig"
        [[ -f "$BASE_DIR/ProxMenux-Monitor.AppImage" ]] && cp -a "$BASE_DIR/ProxMenux-Monitor.AppImage" "$backup_dir/ProxMenux-Monitor.AppImage.orig"
        date -u +"%Y-%m-%dT%H:%M:%SZ" > "$backup_dir/.backup_initialized"
        log_ok "Резервная копия оригинальных файлов создана."
    else
        log_info "Эталонная резервная копия в $backup_dir уже существует — сохранена."
    fi
}

install_host_localization() {
    local config_file="$BASE_DIR/config.json"
    local monitor_runtime="$BASE_DIR/monitor-app"

    if [[ ! -d "$BASE_DIR" ]]; then
        log_error "Каталог ProxMenux ($BASE_DIR) не найден."
        log_error "Сначала установите ProxMenux с официального репозитория MacRimi/ProxMenux либо укажите --source-dir <путь>."
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        log_error "Требуется утилита jq. Установите её командой: apt-get update && apt-get install -y jq"
        return 1
    fi

    if [[ "$ASSUME_YES" -eq 0 && -t 0 ]] && command -v whiptail >/dev/null 2>&1; then
        whiptail --title "ProxMenux-Ru ($LOCALE_VERSION)" \
            --yesno "Установить русскую локализацию ProxMenux в каталог:\n  $BASE_DIR\n\nБудет автоматически создана точка отката для безопасного удаления (--uninstall).\n\nПродолжить?" 13 72 || {
            log_warn "Установка отменена пользователем."
            exit 0
        }
    fi

    log_info "Проверка целостности JSON-каталогов перевода..."
    validate_json_file "$BUNDLE_ROOT/lang/ru.json" || { log_error "Повреждён файл lang/ru.json"; return 1; }
    validate_json_file "$BUNDLE_ROOT/AppImage/messages/ru/common.json" || { log_error "Повреждён файл AppImage/messages/ru/common.json"; return 1; }
    log_ok "Файлы локализации проверены (JSON корректен)."

    backup_existing_files

    if [[ "$INSTALL_CLI" -eq 1 ]]; then
        log_info "Установка русской локализации консольного меню (CLI)..."
        mkdir -p "$BASE_DIR/lang" "$BASE_DIR/scripts/menus"
        cp -f "$BUNDLE_ROOT/lang/ru.json" "$BASE_DIR/lang/ru.json"
        [[ -f "$BUNDLE_ROOT/lang/en.json" ]] && cp -f "$BUNDLE_ROOT/lang/en.json" "$BASE_DIR/lang/en.json"
        cp -f "$BUNDLE_ROOT/scripts/menus/config_menu.sh" "$BASE_DIR/scripts/menus/config_menu.sh"
        cp -f "$BUNDLE_ROOT/scripts/utils.sh" "$BASE_DIR/utils.sh"
        [[ -f "$BUNDLE_ROOT/install_proxmenux.sh" ]] && cp -f "$BUNDLE_ROOT/install_proxmenux.sh" "$BASE_DIR/install_proxmenux.sh"
        [[ -f "$BUNDLE_ROOT/install_proxmenux_beta.sh" ]] && cp -f "$BUNDLE_ROOT/install_proxmenux_beta.sh" "$BASE_DIR/install_proxmenux_beta.sh"
        chmod +x "$BASE_DIR/scripts/menus/config_menu.sh" "$BASE_DIR/utils.sh" 2>/dev/null || true
        [[ -f "$BASE_DIR/install_proxmenux.sh" ]] && chmod +x "$BASE_DIR/install_proxmenux.sh" 2>/dev/null || true

        if [[ ! -f "$config_file" ]] || ! jq empty "$config_file" >/dev/null 2>&1; then
            echo '{}' > "$config_file"
        fi

        if [[ "$KEEP_CURRENT_LANG" -eq 0 ]]; then
            local tmp_cfg
            tmp_cfg="$(mktemp)"
            if jq '.language = "ru"' "$config_file" > "$tmp_cfg"; then
                mv "$tmp_cfg" "$config_file"
                log_ok "Активный язык CLI установлен: ru (Русский)."
            else
                rm -f "$tmp_cfg"
                log_error "Не удалось обновить $config_file"
                return 1
            fi
        else
            log_ok "Файлы CLI установлены (текущий язык в config.json оставлен без изменений по флагу --keep-lang)."
        fi
    fi

    if [[ "$INSTALL_MONITOR" -eq 1 ]]; then
        local appimage_src
        if ! appimage_src="$(find_bundled_appimage)"; then
            log_error "Собранный файл AppImage не найден в $BUNDLE_ROOT/AppImage/"
            return 1
        fi
        verify_appimage_sha256 "$appimage_src" || return 1

        log_info "Обновление веб-панели ProxMenux Monitor ($monitor_runtime)..."
        local was_active=0
        if [[ "$NO_SERVICE" -eq 0 ]] && command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet "$MONITOR_SERVICE" 2>/dev/null; then
            was_active=1
            systemctl stop "$MONITOR_SERVICE" >/dev/null 2>&1 || true
        fi

        cp -f "$appimage_src" "$BASE_DIR/ProxMenux-Monitor.AppImage"
        chmod +x "$BASE_DIR/ProxMenux-Monitor.AppImage"

        local extract_tmp
        extract_tmp="$(mktemp -d "$BASE_DIR/.monitor-extract.XXXXXX")"
        if ! (cd "$extract_tmp" && APPIMAGE_EXTRACT_AND_RUN=1 "$BASE_DIR/ProxMenux-Monitor.AppImage" --appimage-extract >/dev/null 2>&1); then
            rm -rf "$extract_tmp"
            log_error "Не удалось распаковать ProxMenux-Monitor.AppImage"
            return 1
        fi

        local old_runtime="$BASE_DIR/.monitor-app.old.$$"
        [[ -d "$monitor_runtime" ]] && mv "$monitor_runtime" "$old_runtime"
        mv "$extract_tmp/squashfs-root" "$monitor_runtime"
        rm -rf "$extract_tmp" "$old_runtime"
        chmod +x "$monitor_runtime/AppRun"

        log_ok "Веб-панель ProxMenux Monitor с поддержкой русского языка развёрнута в $monitor_runtime."

        if [[ "$was_active" -eq 1 ]]; then
            log_info "Запуск службы $MONITOR_SERVICE..."
            if systemctl start "$MONITOR_SERVICE" >/dev/null 2>&1; then
                sleep 2
                if systemctl is-active --quiet "$MONITOR_SERVICE"; then
                    log_ok "Служба $MONITOR_SERVICE успешно перезапущена."
                else
                    log_warn "Служба $MONITOR_SERVICE не перешла в состояние active — проверьте: journalctl -u $MONITOR_SERVICE -n 30"
                fi
            fi
        fi
    fi

    echo "$LOCALE_VERSION" > "$BASE_DIR/.ru_locale_version"
    log_ok "Русская локализация ProxMenux ($LOCALE_VERSION) успешно установлена!"
    log_info "Консольное меню : выполните команду 'menu'"
    log_info "Веб-панель UI   : откройте http://<IP-сервера>:${MONITOR_PORT} (Настройки → Язык интерфейса → Русский)"
    return 0
}

verify_host_localization() {
    local cli_lang_ok=false
    local cli_keys=0
    local cfg_lang=""
    local menu_has_ru=false
    local monitor_bundle_ru=false
    local service_state="skipped"
    local overall_ok=true

    if validate_json_file "$BASE_DIR/lang/ru.json"; then
        cli_lang_ok=true
        if command -v jq >/dev/null 2>&1; then
            cli_keys="$(jq 'length' "$BASE_DIR/lang/ru.json" 2>/dev/null || echo 0)"
        fi
    else
        overall_ok=false
    fi

    if [[ -f "$BASE_DIR/config.json" ]] && command -v jq >/dev/null 2>&1; then
        cfg_lang="$(jq -r '.language // ""' "$BASE_DIR/config.json" 2>/dev/null || echo "")"
    fi
    [[ "$cfg_lang" == "ru" ]] || overall_ok=false

    if [[ -f "$BASE_DIR/scripts/menus/config_menu.sh" ]] && grep -q '"ru"' "$BASE_DIR/scripts/menus/config_menu.sh"; then
        menu_has_ru=true
    else
        overall_ok=false
    fi

    if [[ -d "$BASE_DIR/monitor-app/web/_next" ]] && grep -rq "Панель мониторинга системы Proxmox" "$BASE_DIR/monitor-app/web/_next/" 2>/dev/null; then
        monitor_bundle_ru=true
    else
        overall_ok=false
    fi

    if [[ "$NO_SERVICE" -eq 0 ]] && command -v systemctl >/dev/null 2>&1; then
        service_state="$(systemctl is-active "$MONITOR_SERVICE" 2>/dev/null || true)"
        [[ -z "$service_state" ]] && service_state="unknown"
    fi

    if [[ "$JSON_OUTPUT" -eq 1 ]]; then
        cat <<EOF
{
  "ok": $overall_ok,
  "version": "$LOCALE_VERSION",
  "base_dir": "$BASE_DIR",
  "cli_lang_json_valid": $cli_lang_ok,
  "cli_lang_keys": $cli_keys,
  "active_config_language": "$cfg_lang",
  "config_menu_has_ru": $menu_has_ru,
  "monitor_web_has_ru": $monitor_bundle_ru,
  "monitor_service": "$service_state"
}
EOF
    else
        echo -e "\n${BOLD}Проверка русской локализации ProxMenux ($BASE_DIR):${CL}"
        $cli_lang_ok       && log_ok "lang/ru.json валиден (ключей: $cli_keys)"          || log_error "lang/ru.json отсутствует или повреждён"
        [[ "$cfg_lang" == "ru" ]] && log_ok "Активный язык в config.json: $cfg_lang"    || log_warn  "Активный язык в config.json: '${cfg_lang:-не задан}' (ожидался 'ru')"
        $menu_has_ru       && log_ok "Пункт 'Русский' присутствует в config_menu.sh"     || log_error "Пункт 'Русский' не найден в config_menu.sh"
        $monitor_bundle_ru && log_ok "Веб-панель Monitor содержит русский перевод"       || log_error "Русский перевод не найден в monitor-app/web"
        log_info "Состояние службы $MONITOR_SERVICE: $service_state"
    fi

    $overall_ok && return 0 || return 1
}

uninstall_host_localization() {
    local backup_dir="$BASE_DIR/backup-ru-locale"
    if [[ ! -d "$backup_dir" ]]; then
        log_error "Резервная копия для отката не найдена в $backup_dir"
        return 1
    fi

    local was_active=0
    if [[ "$NO_SERVICE" -eq 0 ]] && command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet "$MONITOR_SERVICE" 2>/dev/null; then
        was_active=1
        systemctl stop "$MONITOR_SERVICE" >/dev/null 2>&1 || true
    fi

    log_info "Восстановление оригинальных файлов из $backup_dir..."
    rm -f "$BASE_DIR/lang/ru.json" "$BASE_DIR/lang/en.json" "$BASE_DIR/.ru_locale_version"
    [[ -f "$backup_dir/config.json.orig" ]] && cp -a "$backup_dir/config.json.orig" "$BASE_DIR/config.json"
    [[ -f "$backup_dir/utils.sh.orig" ]] && cp -a "$backup_dir/utils.sh.orig" "$BASE_DIR/utils.sh"
    [[ -f "$backup_dir/install_proxmenux.sh.orig" ]] && cp -a "$backup_dir/install_proxmenux.sh.orig" "$BASE_DIR/install_proxmenux.sh"
    [[ -f "$backup_dir/install_proxmenux_beta.sh.orig" ]] && cp -a "$backup_dir/install_proxmenux_beta.sh.orig" "$BASE_DIR/install_proxmenux_beta.sh"
    [[ -f "$backup_dir/config_menu.sh.orig" ]] && cp -a "$backup_dir/config_menu.sh.orig" "$BASE_DIR/scripts/menus/config_menu.sh"

    if [[ -f "$backup_dir/ProxMenux-Monitor.AppImage.orig" ]]; then
        cp -a "$backup_dir/ProxMenux-Monitor.AppImage.orig" "$BASE_DIR/ProxMenux-Monitor.AppImage"
        chmod +x "$BASE_DIR/ProxMenux-Monitor.AppImage"
        local extract_tmp
        extract_tmp="$(mktemp -d "$BASE_DIR/.monitor-restore.XXXXXX")"
        if (cd "$extract_tmp" && APPIMAGE_EXTRACT_AND_RUN=1 "$BASE_DIR/ProxMenux-Monitor.AppImage" --appimage-extract >/dev/null 2>&1); then
            rm -rf "$BASE_DIR/monitor-app"
            mv "$extract_tmp/squashfs-root" "$BASE_DIR/monitor-app"
            chmod +x "$BASE_DIR/monitor-app/AppRun"
        fi
        rm -rf "$extract_tmp"
    fi

    rm -rf "$backup_dir"

    if [[ "$was_active" -eq 1 ]]; then
        systemctl start "$MONITOR_SERVICE" >/dev/null 2>&1 || true
    fi

    log_ok "Откат завершён — оригинальное состояние ProxMenux полностью восстановлено."
    return 0
}

main() {
    parse_args "$@"

    case "$ACTION" in
        verify)
            verify_host_localization
            exit $?
            ;;
        uninstall)
            uninstall_host_localization
            exit $?
            ;;
        install)
            resolve_bundle_root
            if [[ -n "$SOURCE_TARGET_DIR" ]]; then
                apply_to_source_tree "$SOURCE_TARGET_DIR"
                exit $?
            fi
            install_host_localization
            exit $?
            ;;
    esac
}

main "$@"
