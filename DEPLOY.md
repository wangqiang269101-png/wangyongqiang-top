# wangyongqiang.top 数据看板部署说明

## 访问地址

| 地址 | 状态 |
|------|------|
| **http://wangyongqiang.top** | ✅ 推荐访问（已上线，Clash 已设 DIRECT） |
| https://wangyongqiang.top | ⏳ 待 GitHub 签发证书（DNS 生效后约 10~60 分钟） |
| http://wangyongqiang.top/todo.html | Todo 达成看板 |
| http://wangyongqiang.top/dashboard.html | 综合数据看板 |
| http://wangyongqiang.top/data/todo.json | 静态 JSON 数据 |

> **注意**：浏览器若自动跳转 HTTPS 会报证书错误，请手动输入 `http://` 前缀。

备用 GitHub 地址：https://wangqiang269101-png.github.io/wangyongqiang-top/

## 部署架构

```
用户 → DNSPod（腾讯云 DNS）→ GitHub Pages → 静态 HTML/JS 看板
```

文档 `域名制作成网页.docx` 推荐 Cloudflare Tunnel + 本地 Flask；本方案采用 **GitHub Pages + 腾讯云 DNSPod** 实现零服务器成本的静态看板托管（更适合纯静态展示）。

## 站点文件

- 源码目录：`/Users/wangyongqiang/Desktop/Ai 助手/public-site/`
- 构建脚本：`build_public_site.py`
- GitHub 仓库：https://github.com/wangqiang269101-png/wangyongqiang-top

## DNS 记录（腾讯云 DNSPod）

| 主机记录 | 类型 | 记录值 | 说明 |
|----------|------|--------|------|
| @ | A | 185.199.108.153 | GitHub Pages |
| @ | A | 185.199.109.153 | GitHub Pages |
| @ | A | 185.199.110.153 | GitHub Pages |
| @ | A | 185.199.111.153 | GitHub Pages |
| www | CNAME | wangqiang269101-png.github.io | www 子域（待补全） |

## 更新看板数据

```bash
cd "/Users/wangyongqiang/Desktop/Ai 助手"
python3 build_public_site.py
cd public-site
git add -A && git commit -m "update dashboard" && git push
```

推送后 GitHub Pages 自动重新部署（约 1~3 分钟）。

## 启用 HTTPS

DNS 全球生效后，在 GitHub 仓库 Settings → Pages → 勾选 **Enforce HTTPS**，或：

```bash
gh api repos/wangqiang269101-png/wangyongqiang-top/pages -X PUT \
  --input - <<'EOF'
{"cname":"wangyongqiang.top","https_enforced":true}
EOF
```

## 本地验证

本机若使用 Clash Fake-IP，`dig wangyongqiang.top` 可能显示 `198.18.0.x`，不代表公网状态。用以下命令验证：

```bash
# 公网 DNS
curl -s "https://dns.google/resolve?name=wangyongqiang.top&type=A"

# 直连 GitHub Pages IP
curl -sI -H "Host: wangyongqiang.top" http://185.199.108.153/
```

## Clash / 代理排障（502 或地址栏显示异常域名）

**症状**：地址栏出现 `wangyongqiang.xn--top...` 等乱码域名，或 HTTP 502。

**根因**：
1. Clash Fake-IP 将域名映射为 `198.18.0.x`，浏览器可能显示异常 punycode
2. 默认规则将 `.top` 域名走代理节点，代理对 GitHub Pages HTTPS 返回 502 或证书错误
3. 浏览器自动升级 HTTPS，但 GitHub 尚未签发 `wangyongqiang.top` 证书

**已修复**（Clash Verge 配置）：
- `profiles/rd2fI5spiS7B.yaml`：`DOMAIN,wangyongqiang.top,DIRECT`
- `dns_config.yaml` + `clash-verge.yaml`：`fake-ip-filter` 加入 `wangyongqiang.top`

**用户操作**：
1. 打开 Clash Verge → 当前配置「7月13日」→ 点刷新/重载配置
2. 访问 **http://wangyongqiang.top**（务必带 `http://`，不要 HTTPS）
3. 若仍异常：Clash Verge → 系统代理暂时关闭，再访问

```bash
# 经代理验证（期望 200）
curl -s -o /dev/null -w '%{http_code}' -x http://127.0.0.1:7897 http://wangyongqiang.top
```

## 健康检查

```bash
curl -s -o /dev/null -w '%{http_code}' -H "Host: wangyongqiang.top" http://185.199.108.153/
# 期望 200
```
