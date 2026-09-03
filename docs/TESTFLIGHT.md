# CareMom2 → TestFlight

## Быстрый путь (Xcode)

1. Открой `CareMom2.xcodeproj` в Xcode
2. Выбери target **CareMom2** → **Signing & Capabilities**
   - Team: **66TWNVSJ4U**
   - Automatically manage signing: ✅
3. Устройство: **Any iOS Device (arm64)** (не симулятор)
4. **Product → Archive**
5. В Organizer: **Distribute App → App Store Connect → Upload**
6. Через 5–15 мин: [App Store Connect](https://appstoreconnect.apple.com) → **TestFlight**

## Через терминал

```bash
chmod +x scripts/testflight-release.sh
./scripts/testflight-release.sh
```

Требуется вход в Apple ID в Xcode (**Settings → Apple Accounts**).

---

## Первый раз в App Store Connect

Если приложения ещё нет:

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **Apps** → **+**
2. **New App**
   - Platform: iOS
   - Name: **CareMom**
   - Primary Language: Russian или English
   - Bundle ID: **kemal.CareMom2**
   - SKU: `caremom2` (любой уникальный)
3. **App Information → Privacy Policy URL**  
   Опубликуй `docs/privacy.html` (GitHub Pages, свой сайт) и вставь HTTPS-ссылку.

---

## Обязательно заполнить в App Store Connect

| Поле | Значение |
|------|----------|
| Privacy Policy URL | HTTPS-ссылка на `docs/privacy.html` |
| App Privacy (Nutrition Labels) | Health & Fitness — данные не связаны с пользователем, хранятся на устройстве |
| Export Compliance | Обычно «No» (нет шифрования кроме HTTPS) |
| Content Rights | Свои материалы |
| Age Rating | 4+ |
| Screenshots | Минимум 6.7" и 6.5" (можно из симулятора) |

### App Privacy — что указать

- **Health** — да, хранится на устройстве, не для tracking
- **Photos** — да, функциональность приложения
- **Audio** — голосовые заметки
- **Contact Info** — имя ребёнка (опционально)
- **Tracking** — No

---

## TestFlight — добавить тестировщиков

1. App Store Connect → **TestFlight**
2. Дождись статуса **Ready to Submit** / processing build
3. **Internal Testing** — до 100 человек из вашей команды (мгновенно)
4. **External Testing** — нужен короткий Beta App Review (~24 ч)

---

## Версии

| Поле | Сейчас |
|------|--------|
| Version | 2.1 |
| Build | 1 |
| Bundle ID | kemal.CareMom2 |
| Min iOS | 18.0 |

Перед каждым новым upload увеличивай **Build** (CURRENT_PROJECT_VERSION) в Xcode.

---

## Чеклист перед upload

- [ ] Archive собирается без ошибок (Release)
- [ ] Иконка 1024×1024 есть (`AppIcon-1024.png`)
- [ ] Privacy Policy URL опубликован
- [ ] В приложении: **Ещё → Настройки → Политика конфиденциальности**
- [ ] Протестировано на реальном iPhone

---

## Если upload падает

| Ошибка | Решение |
|--------|---------|
| No profiles for … | Xcode → Settings → Accounts → Download Manual Profiles |
| App Record not found | Создай приложение в ASC с bundle `kemal.CareMom2` |
| Invalid Bundle | Проверь App Groups в Developer Portal для app + widget |
| Missing compliance | Ответь на Export Compliance в email от Apple / ASC |
