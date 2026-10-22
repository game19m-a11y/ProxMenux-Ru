# ProxMenux-Ru — Полная русская локализация ProxMenux

<p align="center">
  <strong>Полный перевод на русский язык интерактивного консольного меню (CLI) и веб-панели мониторинга <code>ProxMenux Monitor</code> для <a href="https://github.com/MacRimi/ProxMenux">MacRimi/ProxMenux</a> (v1.2.6)</strong>
</p>

<p align="center">
  <a href="./INSTALL_RU.md">📖 Инструкция по установке (для человека и ИИ-агента)</a> ·
  <a href="./install_ru.sh">⚙️ Скрипт установки <code>install_ru.sh</code></a> ·
  <a href="./LICENSE">⚖️ Лицензия GPL-3.0</a>
</p>

---

## Быстрая установка на сервер Proxmox VE (одной командой)

Выполните от имени `root` в SSH-сессии или консоли узла Proxmox VE, где уже установлен **ProxMenux**:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/game19m-a11y/ProxMenux-Ru/main/install_ru.sh)
```

Для полностью автоматической (неинтерактивной) установки без запросов подтверждения:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/game19m-a11y/ProxMenux-Ru/main/install_ru.sh) --yes
```

> **Node.js и пересборка на хосте Proxmox не требуются:** в репозиторий уже включён готовый пересобранный образ `AppImage/ProxMenux-1.2.6.AppImage` с контрольной суммой `SHA-256`. Установка занимает ~5 секунд, сохраняет все данные и настройки пользователя и создаёт резервную копию для отката одной командой (`--uninstall`).

Подробное руководство (включая все режимы, наложение на исходный код, самостоятельную сборку и пошаговый протокол для ИИ-агентов) приведено в файле **[INSTALL_RU.md](./INSTALL_RU.md)**.

---

## Что переведено и доработано

Репозиторий **полностью повторяет структуру каталогов и имён файлов** исходного проекта [`MacRimi/ProxMenux`](https://github.com/MacRimi/ProxMenux), поэтому его можно как устанавливать через `install_ru.sh` на рабочий сервер Proxmox VE, так и копировать напрямую поверх исходного дерева `ProxMenux`.

### Полная карта файлов проекта

| Путь в репозитории | Назначение и внесённые изменения |
|---|---|
| `LICENSE` | Официальная лицензия **GNU General Public License v3.0 (GPL-3.0)** — приведена в точное соответствие с исходным проектом `MacRimi/ProxMenux`. |
| `install_ru.sh` | Универсальный установщик, верификатор и деинсталлятор русской локализации (интерактивный режим, `--yes`, `--verify [--json]`, `--source-dir`, `--build-appimage`, `--uninstall`). |
| `INSTALL_RU.md` | Полная инструкция по установке, проверке, обновлению и откату локализации **для человека** и **для ИИ-агента**. |
| `lang/en.json` | Полный эталонный словарь исходных английских строк CLI (**5 386** записей: все 5 350 строк скриптов + заголовки из `$VAR` и экранированные `\n`-варианты). |
| `lang/ru.json` | Полный выверенный русский перевод всех **5 386** строк консольного меню и скриптов ProxMenux (100% покрытие рантайм-вызовов `translate()`). |
| `scripts/menus/config_menu.sh` | В функцию `change_language()` добавлен пункт `"ru" "Русский"` и увеличена высота списка `dialog` (`23 60 9`). |
| `scripts/utils.sh` | В `translate()` добавлено прозрачное сопоставление строковых литералов с `\n` в двойных кавычках Bash при поиске в `jq`. |
| `install_proxmenux.sh` | В функцию `select_language()` добавлены языки `"ru" "Русский"` и `"sv" "Svenska"`. |
| `install_proxmenux_beta.sh` | В функцию `select_language()` бета-установщика добавлены `"ru" "Русский"` и `"sv" "Svenska"`. |
| `AppImage/messages/en/common.json` | Эталонный английский каталог веб-панели `ProxMenux Monitor` (**4 126** ключей, **4 896** строк). |
| `AppImage/messages/ru/common.json` | Нормализованный, объединённый без дубликатов и проверенный русский каталог веб-панели (**4 126** ключей + массив из 65 описаний команд терминала, построчное 1:1 совпадение с `en/common.json`, 0 расхождений плейсхолдеров `{...}`). |
| `AppImage/messages/README.md` | Обновлён список поддерживаемых локалей панели (`ru` включён в перечень 9 полных локалей). |
| `AppImage/lib/i18n/languages.ts` | В тип `LanguageCode` и массив `SUPPORTED_LANGUAGES` добавлен `{ code: "ru", englishName: "Russian", nativeName: "Русский", status: "complete" }`. |
| `AppImage/lib/i18n/provider.tsx` | Подключён импорт `../../messages/ru/common.json` и регистрация `ru` в `MESSAGE_CATALOG` с сохранением всех 8 штатных языков upstream-проекта. |
| `AppImage/components/notification-settings.tsx` | Исправлена транслитерация названия языка ИИ-уведомлений: `"Russkiy"` → `"Русский"`. |
| `AppImage/components/security.tsx` | В `getPluralForm()` добавлено точное русское склонение числительных (`1 / 2–4 / 5+` с учётом исключений `11–14`) для отчётов аудита Lynis. |
| `AppImage/components/system-overview.tsx` | В `formatSystemUptime()` добавлено русское правило множественного числа для времени работы (`1 день`, `21 день`, `22 дня`, `25 дней`). |
| `AppImage/components/virtual-machines.tsx` | В `formatCoreCount()` добавлено русское склонение количества ядер ЦП (`1 ядро`, `24 ядра`, `16 ядер`). |
| `AppImage/components/host-backup.tsx` | В `formatCalendarPreview()` и `formatCalendarDistance()` добавлена локализация дат `systemd OnCalendar` и оставшегося времени (`осталось ...`) для русского языка. |
| `AppImage/ProxMenux-1.2.6.AppImage` | Собранный и проверенный образ `ProxMenux Monitor v1.2.6` со статическим экспортом Next.js 15 и полной поддержкой русского интерфейса. |
| `AppImage/ProxMenux-Monitor.AppImage.sha256` | Актуальная контрольная сумма SHA-256 собранного образа `ProxMenux-1.2.6.AppImage`. |
| `.github/scripts/build_i18n_messages.py` | Добавлена локаль `ru` в `DEFAULT_LANGUAGES` и исправлено сохранение JSON-массивов (`terminal.commandDescriptions`) в `flatten()` / `unflatten()`. |
| `.github/scripts/build_translation_cache.py` | Добавлена локаль `ru` в `DEFAULT_LANGUAGES` и русские метки очистки контекста (`Перевести\|Перевод`, `Контекст`). |
| `.github/scripts/build_web_docs_i18n.py` | Добавлена локаль `ru` в `DEFAULT_LANGUAGES`. |
| `web/i18n/routing.ts` | В маршрутизацию сайта документации добавлена локаль `"ru"`. |
| `web/components/language-switcher.tsx` | В переключатель языков сайта документации добавлена метка `ru`. |
| `web/messages/ru/common.json` | Переведён общий интерфейс сайта документации (навигация, боковое дерево разделов, главная страница, список изменений). |
| `web/messages/{en,es,sk}/common.json` | В языковые словари переключателя добавлен пункт `"ru": "Русский"`. |

---

## Проверка качества

- **Синтаксис и структура JSON:** `AppImage/messages/ru/common.json` (4 126 ключей, 4 896 строк — 0 дубликатов разделов, 0 пропущенных или лишних ключей, 0 ошибок плейсхолдеров `{...}`) и `lang/ru.json` (5 386 ключей) проходят строгую валидацию `jq empty` и `python3 -m json.tool`.
- **Сборка фронтенда и TypeScript:** проверена полная производственная сборка `Next.js 15` (`npm run export` в `AppImage/`), проверка типов `tsc --noEmit` на `lib/i18n/*` без единой ошибки и упаковка SquashFS в `AppImage/ProxMenux-1.2.6.AppImage`.
- **Скрипты Bash:** все `.sh`-файлы проверены `bash -n` и протестированы на полном цикле `install` → `verify --json` → runtime `translate()` → `uninstall`.

---

## Лицензия

Проект распространяется на условиях лицензии **[GNU General Public License v3.0 (GPL-3.0)](./LICENSE)** — в полном соответствии с лицензией оригинального проекта [MacRimi/ProxMenux](https://github.com/MacRimi/ProxMenux/blob/main/LICENSE).
