const SCREENS = [
  { file: "01-onboarding.png", name: "01 · Onboarding", w: 390, h: 844 },
  { file: "02-diary.png", name: "02 · Diary", w: 390, h: 844 },
  { file: "03-diary-empty.png", name: "03 · Diary Empty", w: 390, h: 844 },
  { file: "04-add-entry.png", name: "04 · Add Entry", w: 390, h: 844 },
  { file: "05-quick-temp.png", name: "05 · Quick Temperature", w: 390, h: 844 },
  { file: "06-entry-detail.png", name: "06 · Entry Detail", w: 390, h: 844 },
  { file: "07-medications.png", name: "07 · Medications", w: 390, h: 844 },
  { file: "08-statistics.png", name: "08 · Statistics", w: 390, h: 844 },
  { file: "09-gallery.png", name: "09 · Gallery", w: 390, h: 844 },
  { file: "10-more.png", name: "10 · More", w: 390, h: 844 },
  { file: "11-settings.png", name: "11 · Settings", w: 390, h: 844 },
  { file: "12-children.png", name: "12 · Children", w: 390, h: 844 },
  { file: "13-child-profile.png", name: "13 · Child Profile", w: 390, h: 844 },
  { file: "14-growth.png", name: "14 · Growth", w: 390, h: 844 },
  { file: "15-vaccinations.png", name: "15 · Vaccinations", w: 390, h: 844 },
  { file: "16-app-lock.png", name: "16 · App Lock", w: 390, h: 844 },
  { file: "17-widget-small.png", name: "17 · Widget Small", w: 170, h: 170 },
  { file: "18-widget-medium.png", name: "18 · Widget Medium", w: 360, h: 170 }
];

const BASE = "http://localhost:8765";
const GAP = 80;
const ROW_GAP = 120;

async function importScreens() {
  let x = 0;
  let y = 0;
  let rowHeight = 0;
  const page = figma.currentPage;

  figma.notify("CareMom: импорт 18 экранов…");

  for (const screen of SCREENS) {
    const url = `${BASE}/${screen.file}`;
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Не удалось загрузить ${screen.file}. Запущен ли сервер на :8765?`);
    }

    const bytes = new Uint8Array(await response.arrayBuffer());
    const image = figma.createImage(bytes);

    const frame = figma.createFrame();
    frame.name = screen.name;
    frame.resize(screen.w, screen.h);
    frame.x = x;
    frame.y = y;
    frame.clipsContent = true;
    frame.fills = [{ type: "SOLID", color: { r: 0.988, g: 0.961, b: 0.961 } }];

    const rect = figma.createRectangle();
    rect.resize(screen.w, screen.h);
    rect.fills = [{
      type: "IMAGE",
      scaleMode: "FILL",
      imageHash: image.hash
    }];
    frame.appendChild(rect);
    page.appendChild(frame);

    rowHeight = Math.max(rowHeight, screen.h);
    x += screen.w + GAP;

    if (x > 4200) {
      x = 0;
      y += rowHeight + ROW_GAP;
      rowHeight = 0;
    }
  }

  figma.viewport.scrollAndZoomIntoView(page.children);
  figma.notify("CareMom: готово — 18 экранов на canvas", { timeout: 4000 });
  figma.closePlugin();
}

importScreens().catch((error) => {
  figma.notify(String(error.message || error), { error: true, timeout: 8000 });
  figma.closePlugin();
});
