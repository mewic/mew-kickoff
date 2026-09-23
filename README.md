<div align="center">

# 🚀 mew-kickoff

**Pipeline "สัมภาษณ์จนถึงส่งมอบ" สำหรับ AI coding agent — ให้โมเดลตัวท็อปคิด ให้ตัวเล็กผลิต แล้วให้ตัวท็อปตรวจปิดงาน**

![Claude Code](https://img.shields.io/badge/Claude%20Code-supported-8A2BE2) ![Codex CLI](https://img.shields.io/badge/Codex%20CLI-supported-10a37f) ![Grok CLI](https://img.shields.io/badge/Grok%20CLI-supported-000000) ![skill format](https://img.shields.io/badge/format-agentskills.io-blue)

</div>

---

## มันคืออะไร

`mew-kickoff` คือ **skill** ตัวเดียวที่เปลี่ยนการ "สั่ง AI เขียนโค้ด" ให้เป็น pipeline ที่มีขั้นตอน มี gate และมีคนตรวจงานเสมอ:

1. AI **สัมภาษณ์**คุณเป็นรอบ — ถามทุกข้อที่ถามได้ตอนนี้พร้อมคำตอบแนะนำ แล้วรอคุณตอบ ไม่เดาแทนคุณ
2. เขียน **plan** ที่ระบุว่างานแต่ละชิ้นให้ agent ตัวไหนทำ ด้วยโมเดลอะไร
3. หยุดรอคุณ **approve** ก่อนลงมือทุกครั้ง
4. กระจายงานให้ **worker agent** ทำในบริบทสด แยกจากบทสนทนาหลัก
5. **reviewer** ตรวจทุกชิ้นและรัน test เฉพาะส่วนเอง งานเสี่ยงจึงเพิ่ม whole-branch/security review แล้วโมเดลตัวท็อปปิดงาน
6. ส่งมอบพร้อมหลักฐานว่าผ่าน gate ไหนบ้าง

ใช้ได้กับ **Claude Code**, **OpenAI Codex CLI** และ **xAI Grok CLI** จาก source เดียวกัน

> ได้แรงบันดาลใจจาก [mattpocock/skills](https://github.com/mattpocock/skills) และ [superpowers](https://github.com/obra/superpowers) ขอบคุณทั้งสองโปรเจกต์

---

## หลักคิด 3 ข้อ

| หลัก | ความหมาย |
|---|---|
| **Effort economy** | จ่าย effort สูงสุดเฉพาะจุดที่ "การตัดสินใจ" ทบต้น: สัมภาษณ์, spec, review ไม่ใช่ตอนพิมพ์โค้ด |
| **Context economy** | session หลักเก็บบริบทของการสัมภาษณ์กับ plan ให้สะอาด งานผลิตไปเผาบริบทสดของ worker แทน |
| **Review independence** | คนเขียนไม่ใช่คนตัดสิน worker ผลิต, reviewer ตรวจ, session ปิดงาน |

ทำไมถึงเชื่อแบบนี้: เราวัดจริงจาก transcript 5 สัปดาห์ ($16k เทียบราคา API) พบว่า **65% ของต้นทุนคือ session หลักอ่าน context ยาว ๆ ซ้ำทุก turn** ส่วน output ที่ worker ผลิตทั้งหมดรวมกันไม่ถึง 1% ดังนั้นสถาปัตยกรรม "ท็อปคิด เล็กผลิต" ถูกแล้ว สิ่งที่ต้องคุมคือขนาดบริบทของ session หลัก (รายละเอียดใน [`docs/HANDOFF.md`](docs/HANDOFF.md))

---

## ภาพรวม pipeline

```mermaid
flowchart TD
    A([คุณพิมพ์ /mew-kickoff]) --> B{Step 0 · Triage<br/>งานเล็กมาก?}
    B -- ใช่ --> B1[ทำเลย ไม่เข้า pipeline]
    B -- ไม่ --> C[Step 1 · Recon<br/>อ่าน CONTEXT.md, docs/ ที่มีอยู่]
    C --> D[Step 2 · Interview<br/>grilling + domain-modeling<br/>ทั้ง frontier ในรอบเดียว พร้อมคำตอบแนะนำ]
    D --> E[Step 3 · Plan<br/>docs/plans/YYYY-MM-DD-slug.md<br/>Execution Directive · Acceptance Criteria]
    E --> E1{"> 5 task?"}
    E1 -- ใช่ --> E2[mew-critic ตรวจ plan ก่อน]
    E1 -- ไม่ --> F
    E2 --> F
    F{{"🛑 Approval gate<br/>รอคุณพิมพ์ execute หรือ พักไว้"}}
    F -- พักไว้ --> F1[บันทึก plan · จบ session]
    F -- execute --> G[Step 4 · Execute<br/>เปิด session ใหม่ด้วย<br/>/mew-kickoff execute plan-file]
    G --> H[worker agents ทำงานขนาน<br/>ตาม Blocked-by]
    H --> I[Step 5 · Task review<br/>standard สูงสุด 2 fix rounds<br/>high-assurance สูงสุด 5]
    I --> J{Risk?}
    J -- low --> K
    J -- medium/high --> J1[whole-branch review<br/>high เพิ่ม security review]
    J1 --> K
    K[Tier-2 gate<br/>session ตัวท็อปตัดสิน]
    K --> L([Step 6 · Deliver<br/>หลักฐานทุก gate + อัปเดต Status])
```

---

## ทีม agent 5 ตัว + heavy reviewer เมื่อจำเป็น

| Agent | หน้าที่ | Claude Code | Codex | Grok |
|---|---|---|---|---|
| `mew-worker` | งานที่ spec ชัด: โค้ด, test, refactor, ผลิตชิ้นงานด้วย tool **(default)** | Sonnet 5 · high | gpt-5.6-terra · high | grok-4.6 · high |
| `mew-worker-heavy` | งานซับซ้อน หลายไฟล์ debug ยาก งานที่แตะ auth หรือ payment | Opus 5.5 · xhigh | gpt-5.6-sol · xhigh | grok-4.6 · xhigh |
| `mew-worker-mech` | งานกลไกล้วน: rename, แก้ typo, boilerplate ซ้ำ ๆ | Haiku 4.5 | gpt-5.6-luna · medium | grok-4.5 · low |
| `mew-reviewer` | ตรวจ task และ standard branch review ด้วย scoped test | Sonnet 5 · high | gpt-5.6-terra · high | grok-4.6 · high |
| `mew-reviewer-heavy` | whole-branch/security review เฉพาะ high-assurance | Opus override | gpt-5.6-sol · xhigh | grok-4.6 · xhigh |
| `mew-critic` | ตรวจงานที่ไม่ใช่โค้ดและตรวจ plan ด้วยบริบทสด ไม่เห็นบทสนทนา | Opus 5.5 · high | gpt-5.6-terra · high | grok-4.6 · high |

ตัว **session** (คุณคุยด้วย) ใช้โมเดลท็อปสุดที่มีที่ effort สูงสุด และลดลงหนึ่งขั้นตอนกระจายงานใน Step 4

Codex dispatch ทุก agent ด้วย `fork_turns="none"` แล้วส่งเฉพาะ brief/path ที่จำเป็น ทุก agent รายงานกลับมาไม่เกิน 150 คำและเขียนหลักฐานลงไฟล์ เพื่อไม่ให้บทสนทนาหลักบวม

---

## ติดตั้ง

### 1) เตรียม CLI ที่จะใช้

> `install.sh` ในข้อ 2 จะเช็คของพวกนี้ให้และติดตั้งให้ถ้ายังไม่มี ข้อนี้อธิบายว่ามันคืออะไรและใช้คำสั่งอะไร เผื่อต้องทำเอง

<details>
<summary><b>Claude Code</b></summary>

ต้องมี plugin `superpowers` (เป็น execute loop) และ skill ชุดของ Matt Pocock (`grilling`, `domain-modeling`)

```bash
claude plugins install superpowers
npx skills@latest add mattpocock/skills -g -a '*'
```

คำสั่งที่สองจะถามว่าเอา skill ตัวไหน ให้เลือกอย่างน้อย `grilling`, `domain-modeling`, `tdd`, `research`, `wayfinder` เลือกทั้งหมดก็ได้ และเลือกให้ติดตั้งกับทุก agent (`*`) จะได้ใช้ร่วมกับ Codex และ Grok
</details>

<details>
<summary><b>OpenAI Codex CLI</b></summary>

```bash
npx skills@latest add mattpocock/skills -g -a '*'
codex features list | grep multi_agent   # ต้องเป็น stable true
```

Codex อ่าน skill จาก `~/.agents/skills/` และ agent จาก `~/.codex/agents/*.toml` ซึ่ง `install.sh` จะวางให้
</details>

<details>
<summary><b>xAI Grok CLI</b></summary>

```bash
npx skills@latest add mattpocock/skills -g -a '*'
```

Grok อ่าน skill จาก `~/.grok/skills/` และ `~/.agents/skills/` และอ่าน agent จาก `~/.grok/agents/*.md`
</details>

### 2) clone แล้วรัน install.sh

```bash
git clone git@github.com:mewic/mew-kickoff.git ~/projects/mew-kickoff
~/projects/mew-kickoff/install.sh
```

`install.sh` ทำ 2 อย่าง: ติดตั้ง prerequisite ที่ยังขาด (plugin `superpowers` ถ้ามี Claude Code และ skill ชุดของ Matt Pocock ถ้ายังไม่มี `grilling`/`domain-modeling`) แล้วสร้าง symlink จาก directory ของแต่ละ CLI มาที่ repo นี้ ไม่ copy ไฟล์ แก้ที่ repo ที่เดียวทุก CLI เห็นหมด รันซ้ำได้เสมอ

### 3) เปิด session ใหม่ แล้วเช็ค

CLI ทุกตัวอ่าน skill และ agent ตอนเริ่ม session เท่านั้น ปิดแล้วเปิดใหม่ก่อน จากนั้น:

```bash
bash ~/projects/mew-kickoff/skills/mew-kickoff/scripts/smoke.sh
```

ต้องเห็น `SMOKE: PASS` script นี้เช็ค pointer ทุกตัวที่ skill พึ่งพา รวมถึง model economy, fresh-context rule, agent definitions, symlink และความเป็นกลางของ core

---

## วิธีใช้

| ทำอะไร | Claude Code | Codex | Grok |
|---|---|---|---|
| เริ่มงานใหม่ | `/mew-kickoff` | `$mew-kickoff` | `/mew-kickoff` |
| รัน plan ที่ approve แล้ว | `/mew-kickoff execute docs/plans/<file>.md` | `$mew-kickoff execute docs/plans/<file>.md` | `/mew-kickoff execute docs/plans/<file>.md` |

**สิ่งที่จะเกิดขึ้น**

1. ถ้างานไม่มี design decision, ความเสี่ยงต่ำ และตรวจจบได้เป็นหนึ่ง bounded change จะเข้า off-ramp โดยไม่ดูจำนวนไฟล์ พิมพ์ `เข้า pipeline เต็ม` ถ้าอยากบังคับ
2. AI ถามทั้ง frontier ในรอบเดียว พร้อมคำตอบที่แนะนำ **ข้อเท็จจริง**มันไปหาเอง **การตัดสินใจ**มันจะรอคุณเสมอ
3. ได้ plan ที่มี Execution Directive, Acceptance Criteria และ Assurance/Budget ระบุ risk, fix-round ceiling, concurrency และ usage checkpoints
4. AI หยุดที่ **approval gate** ตอบ `execute` เพื่อไปต่อ หรือ `พักไว้` เพื่อเก็บ plan ไว้ทำวันหลัง
5. ตอน execute แนะนำให้ **เปิด session ใหม่** แล้วสั่ง `execute <plan-file>` เพื่อให้บริบทสะอาด และลด effort ของ session ลงหนึ่งขั้น (`/effort high` ใน Claude Code) แล้วกลับเป็นสูงสุดตอน gate สุดท้าย
6. ทุก task ถูก review; low risk รัน full suite แล้วเข้า final gate ส่วน medium/high เพิ่ม whole-branch review และ high เพิ่ม security review
7. งานเสร็จ AI รายงานหลักฐาน build/test, criteria checklist, usage checkpoints และอัปเดต Status ใน plan

**เอกสารที่ pipeline สร้างในโปรเจกต์ของคุณ**

```
CONTEXT.md            glossary ของโปรเจกต์ (อัปเดตในที่ ไม่สร้างใหม่)
docs/adr/             decision records
docs/plans/           plan ต่อ 1 งาน ขึ้นต้นด้วยวันที่ ลบได้หลังส่งมอบ
docs/plans/reports/   รายงานเต็มของ worker/reviewer
docs/research/        ผล research จาก primary source
docs/deliverables/    งานที่ไม่ใช่โค้ด เช่น strategy doc
```

---

## โครงสร้าง repo

```
skills/mew-kickoff/
  SKILL.md                 กระบวนการ กลางทุก CLI
  adapters/claude.md       วิธี dispatch, effort, security review, ตาราง model สำหรับ Claude Code
  adapters/codex.md        เช่นเดียวกันสำหรับ Codex
  adapters/grok.md         เช่นเดียวกันสำหรับ Grok
  adapters/loop.md         execute loop ขั้นต่ำสำหรับ CLI ที่ไม่มี superpowers
  map.md                   วิธีเขียน "map" เมื่องานใหญ่เกิน 1 plan
  ultracode.md             เกณฑ์เสนอ review แบบ multi-agent (Claude Code)
  agents/openai.yaml       metadata สำหรับ Codex
  scripts/smoke.sh         ตัวเช็คว่าทุก pointer ยังใช้ได้
agents/claude|codex|grok/  นิยาม 5 base roles; Codex/Grok มี conditional heavy reviewer
docs/                      plan, รายงาน critic, ผลทดสอบข้าม CLI, research, handoff
scripts/                   script วัด token และต้นทุนจาก transcript ของ Claude Code
install.sh                 สร้าง symlink เข้า CLI ทั้งสาม
```

---

## ปรับให้เป็นของคุณ

| อยากเปลี่ยน | แก้ที่ไหน |
|---|---|
| ชื่อผู้ใช้ (ตอนนี้ skill เรียกคุณว่า "Mew") | แทนคำว่า `Mew` ใน `skills/mew-kickoff/SKILL.md`, `adapters/*.md` และ `agents/*/mew-*` ด้วยชื่อคุณ หรือปล่อยไว้ก็ได้ AI เข้าใจว่าหมายถึงคุณ |
| model หรือ effort ของ agent | Claude: frontmatter ใน `agents/claude/*.md` · Codex: `model` และ `model_reasoning_effort` ใน `agents/codex/*.toml` · Grok: `model:` และ `effort:` ใน `agents/grok/*.md` |
| model ของ session | Claude: `/model` และ `/effort` · Codex: `~/.codex/config.toml` · Grok: `~/.grok/config.toml` |
| ภาษาที่ใช้สัมภาษณ์ | หัวข้อ **Language** ใน `SKILL.md` (ค่าเริ่มต้น: เอกสารเทคนิคอังกฤษ สัมภาษณ์ไทย) |
| เพิ่ม agent ตัวที่ 6 | เพิ่มไฟล์ใหม่ใน `agents/<cli>/` แล้วอ้างชื่อใน Execution Directive อย่าแก้ไฟล์ agent ระหว่างที่มี session รันอยู่ |

แก้เสร็จให้รัน `smoke.sh` และเปิด session ใหม่เสมอ

---

## คำถามที่พบบ่อย

**พิมพ์ `/mew-kickoff` แล้วไม่ขึ้น** — เปิด session ใหม่หรือยัง? skill ถูกอ่านตอนเริ่ม session และตั้งใจให้ AI มองไม่เห็นในรายการอัตโนมัติ คุณต้องเป็นคนเรียกเอง

**AI บอกว่า Skill tool ปฏิเสธ `grill-with-docs`** — คุณใช้ skill เวอร์ชันเก่า อัปเดต repo แล้วรัน `smoke.sh`

**แก้ไฟล์ agent แล้วไม่มีผล** — ไฟล์ agent มีผลกับ session ใหม่เท่านั้น ทุก CLI

**ทำไม Codex แยก Sol/Terra/Luna** — usage allowance คิดตาม model, context, reasoning และ tool work แม้ใช้ subscription จึงใช้ Sol เฉพาะงานหนัก, Terra กับงานผลิต/ตรวจทั่วไป และ Luna กับงานกลไก ส่วน Grok ยังใช้โมเดลเดียวและแยกด้วย effort

**ช้าและกิน token** — เช็คว่า plan ใช้ `standard` หรือ `high-assurance`, Codex agent มี `fork_turns="none"`, และ role mapping ผ่าน smoke แล้ว ดู usage ก่อน execute/หลังแต่ละ frontier/ก่อน final gate; ถึง budget ceiling ให้ session ตัดสิน ไม่เปิด agent เพิ่มอัตโนมัติ

---

## เครดิต

- [mattpocock/skills](https://github.com/mattpocock/skills) — grilling, domain-modeling, wayfinder, writing-for-agents และวิธีคิดเรื่อง skill ทั้งหมด
- [superpowers](https://github.com/obra/superpowers) — subagent-driven-development ที่เป็น execute loop ของฝั่ง Claude Code
- [agentskills.io](https://agentskills.io) — สเปก SKILL.md ที่ทำให้ใช้ข้าม CLI ได้

Private repo สำหรับนักเรียนของ Mew · ถามได้ในคลาส
