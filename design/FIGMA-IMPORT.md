# CareMom → Figma

Я не могу войти в твой аккаунт Figma и загрузить файл напрямую.  
Подготовлены **отдельные экраны** — импорт займёт ~5 минут.

**Твой файл Figma:**  
https://www.figma.com/design/LWMP1WTPVRMCOlsybYWpfe/caremom

## Файлы

| Папка / файл | Описание |
|------|----------|
| `screens/` | **18 отдельных HTML** — по одному экрану (удобно для html.to.design) |
| `png/` | **18 PNG** — можно перетащить в Figma как референс |
| `CareMom-All-Screens.html` | Все экраны на одной странице |
| `figma-tokens.json` | Цвета и отступы |
| `FIGMA-SCREENS.md` | Таблица всех экранов |

Пересобрать PNG/HTML: `python3 design/export-figma-screens.py`

## Авто-импорт через плагин (самый быстрый)

> Сервер PNG уже может быть запущен на `http://localhost:8765`

1. Открой Figma файл (войди в аккаунт):  
   https://www.figma.com/design/LWMP1WTPVRMCOlsybYWpfe/caremom

2. **Plugins → Development → Import plugin from manifest…**  
   Выбери: `design/figma-plugin/manifest.json`

3. Запусти сервер (если не запущен):
   ```bash
   ./design/import-to-figma.sh
   ```

4. **Plugins → Development → CareMom Import Screens → Run**

Все 18 экранов появятся на canvas автоматически.

---

## Импорт в твой файл Figma (html.to.design)

### Шаг 1 — открой Figma
1. Перейди по ссылке выше и **войди в аккаунт**
2. Открой пустую страницу (Page 1) в файле `caremom`

### Шаг 2 — установи плагин
1. **Resources** (иконка ⊞) → **Plugins** → **Browse in Community**
2. Найди **[html.to.design](https://www.figma.com/community/plugin/1159128368874423068/html-to-design)** → **Install**

### Шаг 3 — импортируй экраны
1. **Plugins → html.to.design → Run**
2. **Import from file** (или **Import from browser tab**)
3. Выбери файлы из папки:
   ```
   /Users/kemalz/Documents/swift project /CareMom2/design/screens/
   ```
4. Начни с `01-onboarding.html`, затем `02-diary.html` … до `18-widget-medium.html`
5. Каждый импорт → **Place on canvas** — расставь фреймы в ряд

> **Совет:** импортируй по 3–4 экрана за раз, чтобы плагин не завис.

### Шаг 4 — цвета (опционально)
1. Плагин **Tokens Studio for Figma**
2. Import → `figma-tokens.json`
3. Создай Color Variables / Styles

## Альтернатива — перетащить PNG

1. Открой Finder → `design/png/`
2. Выдели все PNG → перетащи в Figma

Минус: слои не редактируемые, только картинки.

## Размеры фреймов

| Тип | Размер |
|-----|--------|
| Экраны приложения | 390 × 844 |
| Widget Small | 170 × 170 |
| Widget Medium | 360 × 170 |
