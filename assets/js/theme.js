(() => {
  const root = document.documentElement;
  const storageKey = "amalgamator-theme";

  const preferred = () => {
    const saved = localStorage.getItem(storageKey);
    if (saved === "light" || saved === "dark") return saved;
    return window.matchMedia("(prefers-color-scheme: dark)").matches
      ? "dark"
      : "light";
  };

  const apply = (theme) => {
    root.setAttribute("data-theme", theme);
    localStorage.setItem(storageKey, theme);
    const btn = document.querySelector("[data-theme-toggle]");
    if (btn) {
      btn.setAttribute(
        "aria-label",
        theme === "dark" ? "Switch to light mode" : "Switch to dark mode",
      );
    }
  };

  apply(preferred());

  document.addEventListener("click", (event) => {
    const btn = event.target.closest("[data-theme-toggle]");
    if (!btn) return;
    const next =
      root.getAttribute("data-theme") === "dark" ? "light" : "dark";
    apply(next);
  });
})();
