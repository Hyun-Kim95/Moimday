const screens = [
  { id: "s01", title: "S01 온보딩" },
  { id: "s02", title: "S02 OTP 로그인" },
  { id: "s03", title: "S03 그룹·초대" },
  { id: "s04", title: "S04 홈" },
  { id: "s05", title: "S05 모임 목록" },
  { id: "s06", title: "S06 모임 만들기" },
  { id: "s07-poll", title: "S07 투표 중" },
  { id: "s07-attend", title: "S07 참석 수집" },
  { id: "s13", title: "S13 투표 집계" },
  { id: "s14", title: "S14 일시 확정" },
  { id: "s09", title: "S09 일정" },
  { id: "s10", title: "S10 알림" },
  { id: "s11", title: "S11 설정" },
  { id: "s12", title: "S12 도움말" },
];

const tabScreens = {
  s04: "s04",
  s05: "s05",
  s09: "s09",
  s10: "s10",
  s11: "s11",
};

function showScreen(id) {
  document.querySelectorAll(".screen").forEach((el) => {
    el.classList.toggle("active", el.id === id);
  });
  const sel = document.getElementById("screenSelect");
  if (sel) sel.value = id;
}

function renderTabs(activeId) {
  document.querySelectorAll("[data-tab-root]").forEach((nav) => {
    const root = nav.getAttribute("data-tab-root");
    nav.innerHTML = "";
    const tabs = [
      { id: "s04", icon: "🏠", label: "홈" },
      { id: "s05", icon: "📋", label: "모임" },
      { id: "s09", icon: "📅", label: "일정" },
      { id: "s10", icon: "🔔", label: "알림" },
      { id: "s11", icon: "⚙️", label: "설정" },
    ];
    tabs.forEach((t) => {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "tab-item" + (t.id === activeId ? " active" : "");
      btn.innerHTML = `<span class="tab-icon">${t.icon}</span>${t.label}`;
      btn.addEventListener("click", () => showScreen(t.id));
      nav.appendChild(btn);
    });
  });
}

document.addEventListener("DOMContentLoaded", () => {
  const select = document.getElementById("screenSelect");
  screens.forEach((s) => {
    const opt = document.createElement("option");
    opt.value = s.id;
    opt.textContent = s.title;
    select.appendChild(opt);
  });
  select.addEventListener("change", () => showScreen(select.value));

  document.getElementById("themeToggle").addEventListener("click", () => {
    const phone = document.getElementById("phone");
    const dark = phone.getAttribute("data-theme") === "dark";
    phone.setAttribute("data-theme", dark ? "light" : "dark");
  });

  let s07Poll = true;
  document.getElementById("s07StateToggle").addEventListener("click", () => {
    s07Poll = !s07Poll;
    showScreen(s07Poll ? "s07-poll" : "s07-attend");
  });

  document.querySelectorAll("[data-goto]").forEach((el) => {
    el.addEventListener("click", () => {
      const id = el.getAttribute("data-goto");
      const s07 = el.getAttribute("data-s07");
      if (s07 === "poll") showScreen("s07-poll");
      else if (s07 === "attend") showScreen("s07-attend");
      else showScreen(id);
    });
  });

  const sheetVote = document.getElementById("sheetVote");
  const sheetAttend = document.getElementById("sheetAttend");
  document.getElementById("openVoteSheet")?.addEventListener("click", () => sheetVote?.showModal());
  document.getElementById("openAttendSheet")?.addEventListener("click", () => sheetAttend?.showModal());
  document.getElementById("closeVote")?.addEventListener("click", () => sheetVote?.close());
  document.getElementById("closeAttend")?.addEventListener("click", () => sheetAttend?.close());

  renderTabs("s04");
  showScreen("s04");
});
