# Cortex AI Gateway - Tutorial Implementasi Step-by-Step

> 🇬🇧 English version: [readme.md](readme.md)

Panduan praktis untuk mengelola (govern) setiap panggilan LLM dan MCP dari agent, aplikasi, dan coding assistant Anda melalui **Snowflake Cortex AI Gateway**.

> **Status:** Cortex AI Gateway masih berstatus **Preview** dan tersedia di **AWS commercial region** yang didukung. Kapabilitas yang masih roadmap ditandai dengan jelas. Selalu cek [dokumentasi resmi](https://docs.snowflake.com/) sebelum dipakai di production.

---

## 1. Mengapa Cortex AI Gateway?

Enterprise bergerak cepat dari chatbot ke **agent yang bertindak**: agent menjalankan query, membaca file, membuat tiket, dan mengirim pesan melalui LLM dan MCP (Model Context Protocol) tools. Setiap tim memilih model, SDK, dan API key sendiri, sehingga koneksi ke AI tersebar dan tidak terkelola:

```
TANPA GATEWAY                             DENGAN CORTEX AI GATEWAY
Coding agent --key--> Provider A          Coding agent --+      +---------------------+ --> Provider A
App ----------key--> Provider B           App -----------+----> | CORTEX AI GATEWAY   | --> Provider B
AI agent -----key--> Provider C           AI agent ------+      | identitas, model,   | --> Provider C
              key--> MCP tools                                  | biaya, trace        | --> MCP tools
Key, biaya, dan log tersebar                                    +---------------------+
                                          Satu checkpoint terkelola di dalam akun Snowflake Anda
```

Cortex AI Gateway adalah **control plane netral** di akun Snowflake Anda. Semua AI client melewati gateway ini untuk mengakses model dan tools.

- **Tidak ada yang perlu di-deploy.** Setiap akun sudah punya satu objek gateway bernama `SNOWFLAKE`.
- **Drop-in compatible.** Mendukung API OpenAI (`/v1/chat/completions`) dan Anthropic (`/v1/messages`), jadi cukup mengganti `base_url`.
- **Data dan trace milik Anda.** Inference berjalan di Snowflake Cortex, dan setiap request tercatat sebagai trace di akun **Anda** (`AGENT_TRACE_TABLE`). Trace diatur dengan RBAC dan bisa di-join dengan data bisnis lewat SQL.
- **Tanpa markup harga.** Inference ditagih sama seperti Cortex inference.

## 2. Masalah yang Diselesaikan

| # | Masalah | Tanpa gateway | Dengan Cortex AI Gateway |
|---|---|---|---|
| 1 | **Biaya AI lepas kendali** | Tagihan dari banyak vendor datang terlambat dan tidak bisa dipecah per tim. Pemborosan baru ketahuan setelah budget habis. | Biaya per user, tim, dan aplikasi terlihat di satu tempat. Budget memberi notifikasi, dan quota per user **memblokir** request saat limit tercapai. |
| 2 | **API key tersebar** | Key provider ada di laptop, file `.env`, repo, dan CI/CD, dan harus dirotasi manual. | Tidak ada key provider di client. User memakai identitas Snowflake (PAT, OAuth, atau SSO); cabut role berarti akses langsung hilang. |
| 3 | **Shadow AI dan compliance** | Tidak ada yang bisa menjawab "apa yang dilakukan AI terhadap data nasabah?" | Setiap panggilan menjadi trace di akun Anda, bisa di-query dengan SQL, dan dilindungi RBAC dan masking. |
| 4 | **Model tidak disetujui** | Siapa pun bisa memanggil model apa pun. | **Model allowlist** di spec gateway mengatur model mana yang boleh dipanggil. |
| 5 | **Tools (MCP) tanpa kontrol** | Agent bisa terhubung ke MCP server mana saja dan memanggil tool apa saja. | Katalog MCP terkelola, dengan enable/disable per tool dan monitoring penggunaannya. |
| 6 | **Provider lock-in** | Ganti model berarti ubah kode, SDK, dan credential di setiap aplikasi. | Satu endpoint untuk banyak keluarga model; ganti model cukup mengganti nama model. |
| 7 | **Biaya tidak bisa diatribusikan** | Hanya ada satu tagihan gabungan. | Service user per aplikasi plus tag cost center memberi chargeback dan showback per departemen. |

## 3. Penjelasan Setiap Fitur

### 3.1 Unified inference endpoint
`/v1/chat/completions` (kompatibel OpenAI) dan `/v1/messages` (kompatibel Anthropic). Satu endpoint memberi akses ke model Anthropic, OpenAI, Meta, Mistral, DeepSeek, Snowflake, dan lainnya, sesuai ketersediaan di region Anda. → *Langkah 5 tutorial*

### 3.2 Identitas terpusat dan kontrol akses (RBAC)
- `USAGE` pada gateway, ditambah database role `SNOWFLAKE.CORTEX_USER`, memberi hak mengirim inference request.
- `MONITOR` memberi hak membaca trace dan usage semua user.
- Client melakukan autentikasi dengan PAT atau OAuth token Snowflake.
- Dengan **satu service user per aplikasi**, biaya bisa diatribusikan per aplikasi.

→ *Langkah 1*

### 3.3 Gateway specification (model allowlist dan logging)
Spec YAML adalah control plane-nya. Spec menentukan model yang diekspos serta apakah trace dan payload dicatat. `ALTER AI GATEWAY ... FROM SPECIFICATION` **mengganti seluruh spec**, jadi selalu simpan snapshot hasil `DESCRIBE` terlebih dahulu. → *Langkah 2*

### 3.4 Cost governance (tag, budget, quota)
- **Tag** (`COST_CENTER`) mengatribusikan biaya ke tim.
- **Budget** untuk showback dan notifikasi; budget tidak memblokir request.
- **Quota** menetapkan limit per user (harian, mingguan, atau bulanan) dan bisa **memblokir** request saat limit tercapai. Batasi scope quota dengan tag terlebih dahulu.

→ *Langkah 3*

### 3.5 Observability (trace dan span)
- **Trace** adalah satu giliran agent end-to-end. **Span** adalah satu langkah di dalamnya (LLM call atau tool call), lengkap dengan model, token, latensi, dan status.
- Span dari gateway (server-side) dan span OpenTelemetry dari client masuk ke `AGENT_TRACE_TABLE` yang sama.
- `SNOWFLAKE.ACCOUNT_USAGE.AI_GATEWAY_USAGE_HISTORY` adalah sumber resmi untuk tagihan.
- Snowsight menyediakan dashboard.

→ *Langkah 4*

### 3.6 Integrasi coding agent
`snow ai claude` dan `snow ai opencode` (Snowflake CLI) menjalankan Claude Code atau OpenCode melalui gateway memakai koneksi Snowflake Anda. Developer tidak pernah memegang key provider. → *Langkah 5d*

### 3.7 MCP governance
Katalog MCP connector terkelola (misalnya Slack, Jira, GitHub, Salesforce) dan custom MCP server. Tool bisa di-enable atau di-disable satu per satu, misalnya Slack `search` boleh tetapi `postMessage` tidak, dan penggunaannya dimonitor. Konfigurasi dilakukan di Snowsight; ketersediaannya bisa berbeda selama Preview.

### 3.8 Kapabilitas roadmap (belum tersedia umum)
Kapabilitas berikut sudah diumumkan sebagai segera hadir atau preview, dan mungkin belum ada di akun Anda:
- Dynamic model routing.
- Rate limit dan fallback.
- Guardrail terpusat: deteksi prompt injection, redaksi PII, dan content safety.
- Custom guardrail LLM-as-judge.
- Deteksi aktivitas berbahaya di sepanjang sesi agent.
- Dukungan untuk lebih banyak agent native Snowflake.

Rencanakan, tetapi jangan bergantung pada kapabilitas ini dulu.

## 4. Struktur Repository

```
cortex-ai-gateway-tutorial/
├── readme.md / readme-ind.md
├── sql/
│   ├── 00_prerequisites.sql    # cek region, SHOW / DESCRIBE gateway
│   ├── 01_setup_rbac.sql       # role, service user, PAT
│   ├── 02_gateway_spec.sql     # model allowlist + logging
│   ├── 03_cost_controls.sql    # tag, quota, budget
│   ├── 04_observability.sql    # trace, usage, chargeback
│   └── 99_teardown.sql
└── clients/
    ├── requirements.txt
    ├── openai_sdk_example.py   # /v1/chat/completions
    ├── anthropic_sdk_example.py# /v1/messages
    ├── curl_example.sh
    └── coding_agents.md        # snow ai claude / opencode
```

## 5. Langkah Implementasi

**Prasyarat:**
- Akun Snowflake di AWS commercial region yang didukung.
- Role `ACCOUNTADMIN` (atau yang setara).
- Python 3.9+.
- [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/index), opsional, untuk coding agent.

| Langkah | File | Yang dilakukan | Fitur |
|---|---|---|---|
| 0 | `sql/00_prerequisites.sql` | Cek region, jalankan `SHOW AI GATEWAYS`, salin `BASE_URL`, simpan snapshot spec | - |
| 1 | `sql/01_setup_rbac.sql` | Buat role app dan monitor, service user, dan PAT | 3.2 |
| 2 | `sql/02_gateway_spec.sql` | Allowlist model dan aktifkan logging | 3.3 |
| 3 | `sql/03_cost_controls.sql` | Tambahkan tag cost center, quota (blokir), dan budget (notifikasi) | 3.4 |
| 4 | Jalankan client di bawah | Kirim request melalui gateway | 3.1 |
| 5 | `sql/04_observability.sql` | Lihat trace, pemakaian token, error, dan chargeback | 3.5 |
| 6 | `sql/99_teardown.sql` | Bersihkan objek dan kembalikan spec awal | - |

### Menjalankan client
```bash
cd clients
pip install -r requirements.txt
export SNOWFLAKE_AI_GATEWAY_URL="<BASE_URL dari SHOW AI GATEWAYS>"
export SNOWFLAKE_PAT="<token dari langkah 1>"

python openai_sdk_example.py      # juga menunjukkan model di luar allowlist ditolak
python anthropic_sdk_example.py
bash curl_example.sh
snow ai claude                    # coding agent melalui gateway
```

**Hasil yang diharapkan:**
- Model yang ada di allowlist menjawab.
- Model di luar allowlist ditolak.
- Sekitar 1 menit kemudian, request muncul di `AGENT_TRACE_TABLE('SNOWFLAKE')` atas nama `SVC_CHATBOT_APP`.

> ⚠️ Cortex REST API langsung (`/api/v2/cortex/...`) **bukan** gateway. Request lewat jalur itu tidak terkena allowlist dan tidak menghasilkan trace gateway. Selalu gunakan `BASE_URL` dari `SHOW AI GATEWAYS`.

## 6. Rekomendasi Rollout

1. **Visibility:** aktifkan logging dan mulai dengan satu tim pilot, misalnya developer yang memakai `snow ai claude`.
2. **Control:** pasang model allowlist, service user per aplikasi, tag cost center, budget, dan quota, lalu revoke `USAGE` dari `PUBLIC`.
3. **Protect:** izinkan hanya MCP tool yang disetujui, dan aktifkan guardrail ketika sudah tersedia.
4. **Optimize:** analisis trace dengan SQL untuk menemukan sesi yang boros token dan memilih model yang tepat per tugas.

## 7. Catatan dan Keterbatasan
- Nama dan ketersediaan model bergantung pada region. Sesuaikan `02_gateway_spec.sql`.
- Kolom usage view bisa berubah selama Preview. Konfirmasi dengan `DESCRIBE VIEW`.
- Quota bisa sedikit overshoot, dan trace kadang bisa hilang (dropped). Gunakan `AI_GATEWAY_USAGE_HISTORY` untuk angka tagihan.
- Jika payload capture diaktifkan, perlakukan trace table sebagai data sensitif.

## Referensi
- [Dokumentasi Snowflake - Cortex AI Gateway](https://docs.snowflake.com/)
- [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/index)

*Ini tutorial komunitas, bukan dokumentasi resmi Snowflake. Uji coba di akun non-production terlebih dahulu.*
