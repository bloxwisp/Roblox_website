/* Accessibility menu: text size, high contrast, underlined links, stop motion, readable font.
   One small file, no third parties. Settings stay in this browser only (localStorage).
   <script src="assets/js/a11y.js" data-lang="he" data-statement="accessibility.html"></script>  (load in <head>) */
(() => {
  const me = document.currentScript;
  const lang = (me && me.dataset.lang) || document.documentElement.lang || 'en';
  const statement = (me && me.dataset.statement) || 'accessibility.html';
  const T = lang.startsWith('he') ? {
    open: 'תפריט נגישות', title: 'נגישות', size: 'גודל טקסט', contrast: 'ניגודיות גבוהה', links: 'הדגשת קישורים',
    motion: 'עצירת אנימציות', font: 'גופן קריא', reset: 'איפוס', close: 'סגירה', statement: 'הצהרת נגישות'
  } : {
    open: 'Accessibility menu', title: 'Accessibility', size: 'Text size', contrast: 'High contrast', links: 'Underline links',
    motion: 'Stop animations', font: 'Readable font', reset: 'Reset', close: 'Close', statement: 'Accessibility statement'
  };
  const KEY = 'a11y-settings';
  const read = () => { try { return JSON.parse(localStorage.getItem(KEY)) || {}; } catch { return {}; } };
  const write = s => { try { localStorage.setItem(KEY, JSON.stringify(s)); } catch {} };
  let s = read();
  const root = document.documentElement;
  const apply = () => {
    root.classList.toggle('a11y-contrast', !!s.contrast);
    root.classList.toggle('a11y-links', !!s.links);
    root.classList.toggle('a11y-motion', !!s.motion);
    root.classList.toggle('a11y-font', !!s.font);
    root.dataset.a11ySize = String(s.size || 0);
  };
  apply();
  // "stop animations" also answers the page's own reduced-motion checks, so scripted motion stays off after reload
  if (s.motion && window.matchMedia) {
    const mm = window.matchMedia.bind(window);
    window.matchMedia = q => /prefers-reduced-motion:\s*reduce/.test(q)
      ? { matches: true, media: q, addEventListener() {}, removeEventListener() {}, addListener() {}, removeListener() {}, onchange: null, dispatchEvent() { return false; } }
      : mm(q);
  }
  const css = `
  html[data-a11y-size="1"] body { zoom: 1.12; } html[data-a11y-size="2"] body { zoom: 1.25; }
  html.a11y-contrast body { filter: contrast(1.35) saturate(1.1); }
  html.a11y-links a { text-decoration: underline !important; text-underline-offset: 3px; }
  html.a11y-motion *, html.a11y-motion *::before, html.a11y-motion *::after { animation: none !important; transition: none !important; scroll-behavior: auto !important; }
  html.a11y-font body, html.a11y-font body * { font-family: Arial, "Segoe UI", system-ui, sans-serif !important; letter-spacing: .01em; }
  .a11y-btn { position: fixed; z-index: 90; bottom: 18px; inset-inline-start: 18px; width: 48px; height: 48px; border-radius: 6px; border: 1px solid rgba(255,255,255,.35);
    background: #12305e; color: #fff; display: grid; place-items: center; cursor: pointer; box-shadow: 0 8px 24px -8px rgba(0,0,0,.5); }
  .a11y-btn svg { width: 28px; height: 28px; }
  .a11y-btn:focus-visible, .a11y-panel button:focus-visible, .a11y-panel a:focus-visible { outline: 3px solid #ffbf47; outline-offset: 2px; }
  .a11y-panel { position: fixed; z-index: 91; bottom: 76px; inset-inline-start: 18px; width: min(300px, calc(100vw - 36px)); background: #fff; color: #111; border-radius: 6px;
    padding: 16px; box-shadow: 0 20px 50px -12px rgba(0,0,0,.55); font: 16px/1.4 Arial, system-ui, sans-serif; }
  .a11y-panel[hidden] { display: none; }
  .a11y-panel h2 { margin: 0 0 12px; font: 700 18px/1.2 Arial, system-ui, sans-serif; color: #111; }
  .a11y-panel .a11y-row { display: grid; grid-template-columns: 1fr auto auto auto; gap: 6px; align-items: center; margin-bottom: 10px; }
  .a11y-panel button { min-height: 40px; border: 1px solid #8a8a8a; border-radius: 4px; background: #f4f4f4; color: #111; font: 600 15px Arial, system-ui, sans-serif; cursor: pointer; padding: 0 10px; }
  .a11y-panel button[aria-pressed="true"] { background: #12305e; color: #fff; border-color: #12305e; }
  .a11y-panel .a11y-toggles { display: grid; gap: 6px; }
  .a11y-panel .a11y-toggles button { text-align: start; }
  .a11y-panel .a11y-foot { display: flex; justify-content: space-between; align-items: center; gap: 8px; margin-top: 12px; }
  .a11y-panel a { color: #12305e; font-weight: 700; }
  @media (max-width: 640px) { body:has(.bar) .a11y-btn { bottom: calc(86px + env(safe-area-inset-bottom)); } body:has(.bar) .a11y-panel { bottom: calc(144px + env(safe-area-inset-bottom)); } }
  @media print { .a11y-btn, .a11y-panel { display: none; } }`;
  const build = () => {
    const st = document.createElement('style'); st.textContent = css; document.head.append(st);
    const btn = document.createElement('button');
    btn.className = 'a11y-btn'; btn.type = 'button'; btn.setAttribute('aria-label', T.open); btn.setAttribute('aria-expanded', 'false'); btn.setAttribute('aria-controls', 'a11y-panel');
    btn.innerHTML = '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><circle cx="12" cy="3.6" r="2.1"/><path d="M4 7.6c0-.6.5-1 1-.9 2.3.4 4.6.6 7 .6s4.7-.2 7-.6c.6-.1 1 .3 1 .9 0 .5-.3.9-.8 1l-4.4.9v4l2.1 6.9c.2.6-.2 1.2-.8 1.3-.5.1-1-.2-1.1-.7L12 15.6 10 21c-.2.5-.6.8-1.1.7-.6-.1-1-.7-.8-1.3l2.1-6.9v-4l-4.4-.9c-.5-.1-.8-.5-.8-1z"/></svg>';
    const p = document.createElement('div');
    p.className = 'a11y-panel'; p.id = 'a11y-panel'; p.hidden = true; p.setAttribute('role', 'dialog'); p.setAttribute('aria-label', T.title);
    p.innerHTML = `<h2>${T.title}</h2>
      <div class="a11y-row"><span>${T.size}</span><button type="button" data-size="0" dir="ltr">A</button><button type="button" data-size="1" dir="ltr">A+</button><button type="button" data-size="2" dir="ltr">A++</button></div>
      <div class="a11y-toggles">
        <button type="button" data-k="contrast">${T.contrast}</button>
        <button type="button" data-k="links">${T.links}</button>
        <button type="button" data-k="motion">${T.motion}</button>
        <button type="button" data-k="font">${T.font}</button>
      </div>
      <div class="a11y-foot"><a href="${statement}">${T.statement}</a><button type="button" data-reset>${T.reset}</button></div>`;
    document.body.append(btn, p);
    const sync = () => {
      p.querySelectorAll('[data-size]').forEach(b => b.setAttribute('aria-pressed', String(+b.dataset.size === (s.size || 0))));
      p.querySelectorAll('[data-k]').forEach(b => b.setAttribute('aria-pressed', String(!!s[b.dataset.k])));
    };
    sync();
    const toggle = open => { p.hidden = !open; btn.setAttribute('aria-expanded', String(open)); if (open) p.querySelector('button').focus(); };
    btn.addEventListener('click', () => toggle(p.hidden));
    document.addEventListener('keydown', e => { if (e.key === 'Escape' && !p.hidden) { toggle(false); btn.focus(); } });
    document.addEventListener('click', e => { if (!p.hidden && !p.contains(e.target) && e.target !== btn && !btn.contains(e.target)) toggle(false); });
    p.addEventListener('click', e => {
      const b = e.target.closest('button'); if (!b) return;
      const hadMotion = !!s.motion;
      if (b.dataset.size) s.size = +b.dataset.size;
      else if (b.dataset.k) s[b.dataset.k] = !s[b.dataset.k];
      else if ('reset' in b.dataset) s = {};
      write(s); apply(); sync();
      if (hadMotion !== !!s.motion) location.reload(); // scripted motion is set up at load
    });
  };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', build); else build();
})();
