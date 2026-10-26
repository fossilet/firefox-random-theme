import { Windows, Prefs } from "chrome://userchromejs/content/uc_api.sys.mjs";

const LOG_PREFIX = "[random-newtab-wallpaper]";
const RECORDS_URL =
    "https://firefox.settings.services.mozilla.com/v1/buckets/main/collections/newtab-wallpapers-v2/records";
const FETCH_TIMEOUT_MS = 15000;

const PREF_ENABLED =
    "browser.newtabpage.activity-stream.newtabWallpapers.enabled";
const PREF_USER_ENABLED =
    "browser.newtabpage.activity-stream.newtabWallpapers.user.enabled";
const PREF_WALLPAPER =
    "browser.newtabpage.activity-stream.newtabWallpapers.wallpaper";

const FALLBACK_TITLES = Object.freeze([
    "dark-panda",
    "light-panda",
    "dark-landscape",
    "light-landscape",
    "dark-mountain",
    "light-mountain",
    "starry-canyon",
    "starry-sky",
    "blue-purple",
    "white-curves",
    "firefox-orange",
]);

let titles = [];
let lastTitle = null;

const log = (...args) => console.log(LOG_PREFIX, ...args);
const warn = (...args) => console.warn(LOG_PREFIX, ...args);

const setPref = (name, value) => {
    try {
        Prefs.set(name, value);
        return true;
    } catch (error) {
        warn(`could not set ${name}:`, error);
        return false;
    }
};

const pickTitle = () => {
    const pool = titles.length ? titles : FALLBACK_TITLES;

    if (!pool.length) {
        return null;
    }

    let index = Math.floor(Math.random() * pool.length);

    if (pool.length > 1 && pool[index] === lastTitle) {
        index = (index + 1 + Math.floor(Math.random() * (pool.length - 1))) %
            pool.length;
    }

    lastTitle = pool[index];
    return lastTitle;
};

const applyRandom = () => {
    setPref(PREF_ENABLED, true);
    setPref(PREF_USER_ENABLED, true);

    const title = pickTitle();

    if (!title) {
        warn("no wallpaper titles available");
        return;
    }

    if (setPref(PREF_WALLPAPER, title)) {
        log(`wallpaper -> ${title}`);
    }
};

const refreshTitles = async () => {
    try {
        const response = await fetch(RECORDS_URL, {
            credentials: "omit",
            signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status} ${response.statusText}`);
        }

        const payload = await response.json();
        const records = Array.isArray(payload?.data) ? payload.data : [];
        const seen = new Set();
        const nextTitles = [];

        for (const record of records) {
            const title = record?.title;

            if (
                typeof title !== "string" ||
                !title ||
                record.visible === false ||
                typeof record.attachment?.location !== "string" ||
                !record.attachment.location ||
                seen.has(title)
            ) {
                continue;
            }

            seen.add(title);
            nextTitles.push(title);
        }

        if (!nextTitles.length) {
            throw new Error("response contained no usable wallpaper records");
        }

        titles = nextTitles;
        log(`loaded ${titles.length} wallpaper titles`);
    } catch (error) {
        warn("could not refresh wallpaper titles; using fallback list:", error);
    }
};

const attach = win => {
    if (!win || win.__randomNewTabWallpaper) {
        return;
    }

    try {
        if (!Windows.isBrowserWindow(win)) {
            return;
        }
    } catch {
        return;
    }

    const tabContainer = win.gBrowser?.tabContainer;

    if (!tabContainer) {
        return;
    }

    win.__randomNewTabWallpaper = true;
    tabContainer.addEventListener("TabOpen", () => applyRandom());
};

const attachWhenReady = win => {
    if (!win?.isChromeWindow) {
        return;
    }

    Windows.waitWindowLoading(win)
        .then(() => attach(win))
        .catch(error => warn("could not attach to window:", error));
};

setPref(PREF_ENABLED, true);
setPref(PREF_USER_ENABLED, true);
applyRandom();
refreshTitles();

Windows.forEach((doc, win) => attach(win), true);
Windows.onCreated(attachWhenReady);

log("loaded");
