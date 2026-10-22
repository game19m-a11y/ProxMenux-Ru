# Инструкция по установке русской локализации ProxMenux (`ProxMenux-Ru`)

Настоящий документ содержит два полноценных руководства:

1. **[Часть 1 — Для человека (администратора Proxmox VE / разработчика)](#часть-1--инструкция-для-человека)**
2. **[Часть 2 — Для ИИ-агента (детерминированный протокол выполнения и верификации)](#часть-2--инструкция-для-ии-агента)**

---

# Часть 1 — Инструкция для человека

## 1. Требования

- Сервер **Proxmox VE 8.x / 9.x** с уже установленным [ProxMenux](https://github.com/MacRimi/ProxMenux) (каталог `/usr/local/share/proxmenux`).
- Права суперпользователя `root` (подключение по SSH или через физическую/IPMI-консоль узла).
- Стандартные пакеты `curl`, `git`, `jq` (устанавливаются автоматически самим ProxMenux).
- **Установка Node.js на сервер Proxmox НЕ требуется:** готовый собранный образ веб-панели `AppImage/ProxMenux-1.2.6.AppImage` уже включён в репозиторий.

> **Важно:** не запускайте обновление веб-панели из встроенного веб-терминала внутри самой панели `ProxMenux Monitor` (`:8008`), так как при перезапуске службы `proxmenux-monitor.service` сессия этого веб-терминала закроется. Используйте обычный SSH-клиент или консоль узла в веб-интерфейсе Proxmox VE (`:8006`).

---

## 2. Способ А — Быстрая установка одной командой (рекомендуется)

Подключитесь к узлу Proxmox VE под `root` и выполните:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/game19m-a11y/ProxMenux-Ru/main/install_ru.sh)
```

Если нужно выполнить установку без диалогового окна подтверждения:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/game19m-a11y/ProxMenux-Ru/main/install_ru.sh) --yes
```

Что сделает скрипт за ~5 секунд:
1. Проверит валидность всех JSON-каталогов перевода и SHA-256 образа `ProxMenux-1.2.6.AppImage`.
2. Создаст точку отката оригинальных файлов в `/usr/local/share/proxmenux/backup-ru-locale/` (позволяет в любой момент полностью вернуть исходное состояние).
3. Установит русский языковой пакет `lang/ru.json`, добавит пункт **«Русский»** в меню смены языка (`config_menu.sh`) и включит `"language": "ru"` в `/usr/local/share/proxmenux/config.json`.
4. Обновит образ `ProxMenux-Monitor.AppImage`, атомарно развернёт обновлённую веб-панель в `/usr/local/share/proxmenux/monitor-app/` (сохранив вашу базу метрик, пароль, 2FA, токены API и настройки уведомлений) и перезапустит службу `proxmenux-monitor.service`.

---

## 3. Способ Б — Клонирование репозитория и гибкие режимы запуска

```bash
git clone https://github.com/game19m-a11y/ProxMenux-Ru.git /opt/ProxMenux-Ru
cd /opt/ProxMenux-Ru
chmod +x install_ru.sh

# Полная установка (CLI + веб-панель Monitor)
./install_ru.sh --yes
```

Дополнительные полезные флаги:

```bash
# Установить перевод только для консольного меню (не трогая ProxMenux Monitor)
./install_ru.sh --yes --cli-only

# Установить перевод только для веб-панели ProxMenux Monitor
./install_ru.sh --yes --monitor-only

# Добавить русский язык в списки выбора, но оставить текущий активный язык
./install_ru.sh --yes --keep-lang

# Проверить статус и целостность установленной локализации
./install_ru.sh --verify
```

---

## 4. Как включить и переключить русский язык в интерфейсе

### В консольном меню (`menu`)
- При стандартной установке русский язык **включается автоматически** — просто введите команду:
  ```bash
  menu
  ```
- Чтобы в любой момент переключить язык вручную: откройте `menu` → **Настройки (Settings)** → **Сменить язык (Change Language)** → выберите **`ru` — `Русский`**.

### В веб-панели `ProxMenux Monitor` (`http://<IP-вашего-сервера>:8008`)
1. Откройте веб-панель в браузере и при необходимости обновите кэш страницы (`Ctrl+F5` / `Cmd+Shift+R`).
2. Если язык браузера — русский, панель выберет **Русский** автоматически при первом визите.
3. Чтобы переключить язык вручную: перейдите в **Admin / Администрирование → Settings / Настройки → Interface Language / Язык интерфейса** и выберите **Русский**.
4. Для получения уведомлений на русском языке (при использовании ИИ-форматирования): откройте **Настройки → Уведомления → ИИ-улучшение** и выберите язык **Русский**.

---

## 5. Способ В — Наложение на исходный код `MacRimi/ProxMenux` и самостоятельная сборка

Так как структура каталогов и имена файлов в `ProxMenux-Ru` полностью повторяют `MacRimi/ProxMenux`, вы можете наложить перевод поверх клона или распакованного архива исходного проекта:

```bash
git clone https://github.com/MacRimi/ProxMenux.git /tmp/ProxMenux
git clone https://github.com/game19m-a11y/ProxMenux-Ru.git /tmp/ProxMenux-Ru

# Скопировать все переведённые файлы с сохранением структуры каталогов
/tmp/ProxMenux-Ru/install_ru.sh --source-dir /tmp/ProxMenux --yes

# (Опционально, при наличии Node.js 20+ и Python 3.11+) пересобрать AppImage с нуля:
/tmp/ProxMenux-Ru/install_ru.sh --source-dir /tmp/ProxMenux --build-appimage --yes
```

---

## 6. Повторное применение после обновления ProxMenux и удаление (откат)

- **После штатного обновления ProxMenux** (через `menu` или `install_proxmenux.sh`) официальный установщик перезаписывает `/usr/local/share/proxmenux/`. Просто повторно выполните команду установки `install_ru.sh --yes`.
- **Полный откат русской локализации** к исходным файлам:
  ```bash
  /opt/ProxMenux-Ru/install_ru.sh --uninstall
  ```
  или без локального клона:
  ```bash
  bash <(curl -fsSL https://raw.githubusercontent.com/game19m-a11y/ProxMenux-Ru/main/install_ru.sh) --uninstall
  ```

---

# Часть 2 — Инструкция для ИИ-агента

Данный раздел представляет собой строгий операционный протокол для автономного ИИ-агента (SSH/CLI/DevOps/Coding Agent), выполняющего установку, верификацию, интеграцию в исходники или откат русской локализации `ProxMenux`.

## 1. Предусловия и правила безопасности

1. **Никогда не выполняй `install_ru.sh` внутри встроенного WebSocket-терминала `ProxMenux Monitor`** (`[[ "${PROXMENUX_TERMINAL:-}" == "monitor" ]]`), если разрешён перезапуск `proxmenux-monitor.service` — остановка сервиса разорвёт дочерний процесс. Работай по SSH, в системной оболочке хоста или передавай `--no-service` с последующим отложенным перезапуском.
2. **Всегда передавай флаг `--yes`**, чтобы исключить блокировку на интерактивных диалогах `whiptail`/`dialog`.
3. **Не удаляй пользовательские данные:** файлы `/usr/local/share/proxmenux/health_monitor.db`, `/usr/local/share/proxmenux/components_status.json` и каталог `/root/.config/proxmenux-monitor/` содержат учётные данные, секреты 2FA и историю мониторинга — `install_ru.sh` гарантированно не затрагивает их.

---

## 2. Сценарий 1 — Автономная установка локализации на узел Proxmox VE

### Шаг 1. Проверка окружения на целевом хосте

```bash
test "$(id -u)" -eq 0
test -d /usr/local/share/proxmenux
command -v jq git curl sha256sum >/dev/null
```

Ожидаемый результат: код возврата `0`. Если отсутствует `jq`, `git` или `curl`, установи их:

```bash
apt-get update && apt-get install -y jq git curl
```

### Шаг 2. Клонирование и неинтерактивная установка

```bash
rm -rf /tmp/proxmenux-ru-agent
git clone --depth 1 https://github.com/game19m-a11y/ProxMenux-Ru.git /tmp/proxmenux-ru-agent
chmod +x /tmp/proxmenux-ru-agent/install_ru.sh
/tmp/proxmenux-ru-agent/install_ru.sh --yes
```

Ожидаемый результат: код возврата `0`.

### Шаг 3. Машиночитаемая верификация постусловий (`--verify --json`)

```bash
VERIFY_JSON="$(/tmp/proxmenux-ru-agent/install_ru.sh --verify --json)"
echo "$VERIFY_JSON"
echo "$VERIFY_JSON" | jq -e '
  .ok == true and
  .cli_lang_json_valid == true and
  .cli_lang_keys >= 5350 and
  .active_config_language == "ru" and
  .config_menu_has_ru == true and
  .monitor_web_has_ru == true
'
```

Ожидаемый результат: `jq -e` выводит `true` и завершается с кодом возврата `0`.

### Шаг 4. Функциональный дымовой тест рантайма CLI и HTTP-ответа Monitor

```bash
bash -c '
  source /usr/local/share/proxmenux/utils.sh
  load_language
  [[ "$LANGUAGE" == "ru" ]]
  [[ "$(translate "Main ProxMenux")" == "Главное меню ProxMenux" ]]
  [[ "$(translate "Select an option:")" == "Выберите пункт:" ]]
'
if systemctl is-active --quiet proxmenux-monitor.service; then
  curl -fsSI http://127.0.0.1:8008/ | head -n 1
fi
rm -rf /tmp/proxmenux-ru-agent
```

Ожидаемый результат: код возврата `0` и HTTP-ответ `200 OK` (если служба `proxmenux-monitor.service` включена на хосте).

---

## 3. Сценарий 2 — Интеграция локализации в дерево исходного кода `MacRimi/ProxMenux`

Если задача агента — подготовить локальную сборку или Pull Request в репозиторий с исходным кодом `ProxMenux` в каталоге `$SRC_DIR`:

```bash
SRC_DIR="/path/to/ProxMenux"
LOCALE_DIR="/tmp/proxmenux-ru-agent"

git clone --depth 1 https://github.com/game19m-a11y/ProxMenux-Ru.git "$LOCALE_DIR"
"$LOCALE_DIR/install_ru.sh" --source-dir "$SRC_DIR" --yes

# 1. Валидация синтаксиса всех JSON-каталогов и Bash-скриптов
python3 -m json.tool "$SRC_DIR/lang/ru.json" > /dev/null
python3 -m json.tool "$SRC_DIR/lang/en.json" > /dev/null
python3 -m json.tool "$SRC_DIR/AppImage/messages/ru/common.json" > /dev/null
python3 -m json.tool "$SRC_DIR/web/messages/ru/common.json" > /dev/null
bash -n "$SRC_DIR/scripts/menus/config_menu.sh" "$SRC_DIR/scripts/utils.sh" \
        "$SRC_DIR/install_proxmenux.sh" "$SRC_DIR/install_proxmenux_beta.sh"

# 2. (При наличии Node.js 20+) проверка сборки статического фронтенда Monitor
cd "$SRC_DIR/AppImage"
npm install --legacy-peer-deps
npm run export
```

> При открытии upstream Pull Request в `MacRimi/ProxMenux` учитывай политику `CONTRIBUTING.md`: целевая ветка в upstream — `develop` (не `main`).

---

## 4. Сценарий 3 — Аварийный откат при сбое верификации

Если любой шаг проверки завершился ненулевым кодом возврата, выполни атомарный откат:

```bash
/tmp/proxmenux-ru-agent/install_ru.sh --uninstall
```

Ожидаемый результат: код возврата `0`, восстановлены исходные файлы `config.json`, `utils.sh`, `config_menu.sh` и `monitor-app/` из `/usr/local/share/proxmenux/backup-ru-locale/`.
