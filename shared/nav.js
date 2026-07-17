document.addEventListener("DOMContentLoaded", function () {
  var items = [
    { label: "新商评", href: "./", page: "xsh" },
    { label: "星级投屏", href: "star-warning.html", page: "star" },
    { label: "预警镜像", href: "star-warning-mirror.html", page: "star-mirror" },
    { label: "团购", href: "tuangou.html", page: "tuangou" },
    { label: "广告达成", href: "ad.html", page: "ad" },
    { label: "基本功", href: "basic.html", page: "basic" },
    { label: "OKR", href: "okr.html", page: "okr" },
  ];
  var current = document.body.getAttribute("data-page") || "xsh";
  var nav = items
    .map(function (item) {
      var cls = item.page === current ? ' class="active"' : "";
      return '<a href="' + item.href + '"' + cls + ">" + item.label + "</a>";
    })
    .join("");
  document.body.insertAdjacentHTML(
    "afterbegin",
    '<div class="app">' +
      '<aside class="sidebar">' +
      '<div class="sidebar-brand">📊 wangyongqiang.top</div>' +
      '<nav class="sidebar-nav">' +
      nav +
      "</nav>" +
      '<div class="sidebar-foot">业务数据看板</div>' +
      "</aside>" +
      '<div class="app-main" id="app-main"></div>' +
      "</div>"
  );
  var main = document.getElementById("app-main");
  Array.from(document.body.children).forEach(function (node) {
    if (node.classList && node.classList.contains("app")) return;
    if (node.tagName === "SCRIPT") return;
    main.appendChild(node);
  });
});
