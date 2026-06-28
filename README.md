# CCF Malware Analysis: WannaCry & NotPetya

A comparative static malware analysis and YARA detection rule suite for the **WannaCry** ransomware and **NotPetya** wiper — two of the most consequential malware incidents of 2017.

**Course:** Computer and Cyber Forensics, Innopolis University, 2026
**Team:** Kehinde Adetunji, Daniel, Meso

---

## Overview

In May and June 2017, two related cyberattacks caused billions of dollars in damage worldwide. **WannaCry** spread as ransomware via the EternalBlue SMB exploit and was halted by the discovery of a kill-switch domain. Weeks later, **NotPetya** used many of the same techniques but with destructive intent — it was a state-sponsored wiper disguised as ransomware, propagated through a compromised software supply chain.

This project performs in-depth static analysis and targeted reverse engineering of canonical samples of each, then produces a **custom YARA rule suite** that identifies each family through multiple detection angles.

The project deliverables are:

1. **Six YARA rules** — three per sample, each targeting a different detection angle (strings, components/behavior, PE structure & imports)
2. **A comparative analysis report** — methodology, findings, kill-chain comparison, defensive recommendations
3. **A demo video** — walking through the rules in action against both samples

---

## Repository structure

```
.
├── README.md                       # This file
├── yara/                           # YARA detection rules
│   ├── wannacry_strings.yar
│   ├── wannacry_components.yar
│   ├── wannacry_pe_structure.yar
│   ├── notpetya_strings.yar
│   ├── notpetya_antiforensics.yar
│   ├── notpetya_dll_structure.yar
│   └── all_rules.yar               # Master include file
├── docs/                           # Project documentation
│   ├── 01_goals_and_team.md
│   ├── 02_methodology.md
│   ├── 03_development_and_tests.md
│   ├── 04_difficulties.md
│   ├── 05_conclusion.md
│   ├── indicators.md
│   └── references.md
└── .gitignore                      # Excludes malware samples from commits
```

---

## Samples analyzed

| Sample | SHA-256 | Type | Family |
|--------|---------|------|--------|
| WannaCry | `ed01ebfbc9eb5bbea545af4d01bf5f1071661840480439c6e5babe8e080e41aa` | PE32 EXE (GUI, 32-bit) | Ransomware |
| NotPetya | `027cc450ef5f8c5f653329641ec1fed91f694e0d229928963b30f6b0d7d3a745` | PE32 DLL (32-bit) | Wiper disguised as ransomware |

Samples were obtained from [MalwareBazaar](https://bazaar.abuse.ch/) (abuse.ch), the authoritative public malware repository for security researchers.

> **Safety note:** Samples are NOT included in this repository (see `.gitignore`). Researchers can obtain canonical samples independently through MalwareBazaar.

---

## YARA rule suite

| Rule | Target | Detection method |
|------|--------|------------------|
| `WannaCry_Strings` | WannaCry | `WNcry@2ol7` key artifact, mutex name, hardcoded BTC wallet addresses |
| `WannaCry_Components` | WannaCry | Dropped components (`tasksche.exe`, `taskdl.exe`, `taskse.exe`), `icacls` permissions command, `.wnry` extension |
| `WannaCry_PE_Structure` | WannaCry | 4-section PE + service control + registry imports combination |
| `NotPetya_Strings` | NotPetya | BTC wallet, `perfc.dat` module name, fake CHKDSK strings, distinctive ransom note opener |
| `NotPetya_AntiForensics` | NotPetya | Hardcoded `wevtutil` log clearing, `fsutil` USN journal deletion, `rundll32` and `wmic` lateral movement commands |
| `NotPetya_DLL_Structure` | NotPetya | DLL with single nameless export + raw disk I/O + forced reboot + Salsa20 random + token theft imports |

Each rule targets a **different detection angle**, providing layered coverage. A variant that obfuscates strings will still trigger the structural rule, and vice versa.

---

## Usage

### Prerequisites

- [YARA](https://github.com/VirusTotal/yara) 4.0+ with `pe` module support (default on most distributions)

Install on Debian / Ubuntu / REMnux:

```bash
sudo apt install yara
```

### Run the full suite against a sample

```bash
git clone https://github.com/Kentunji/ccf-malware-analysis.git
cd ccf-malware-analysis/yara
yara all_rules.yar /path/to/suspected/sample.bin
```

### Run a single rule

```bash
yara wannacry_strings.yar /path/to/sample.bin
```

### Verbose output (shows which strings matched)

```bash
yara -s all_rules.yar /path/to/sample.bin
```

### Example output

```
WannaCry_Strings         /path/to/wannacry_sample.bin
WannaCry_Components      /path/to/wannacry_sample.bin
WannaCry_PE_Structure    /path/to/wannacry_sample.bin
```

---

## Methodology

The project followed a six-stage workflow for each sample:

1. **Triage** — file type identification, hashing, basic metadata extraction
2. **Static PE analysis** — header inspection, section entropy, import/export tables (`pecheck.py`)
3. **String extraction** — ASCII and UTF-16 wide strings, filtered for malware-relevant patterns (`strings`, `floss`)
4. **Cross-referenced research** — findings verified against MITRE ATT&CK, US-CERT, and vendor analyses
5. **Rule authoring** — multi-angle YARA rules; each rule encodes an analytical conclusion
6. **Validation** — every rule tested against BOTH samples to confirm correct detection and no cross-matching

Full methodology details in [`docs/02_methodology.md`](docs/02_methodology.md).

---

## Tools used

| Tool | Purpose |
|------|---------|
| REMnux | Malware-analysis Linux distribution |
| KVM / libvirt | Hypervisor for isolated analysis VM |
| `pecheck.py` (Didier Stevens) | PE structure inspection |
| `strings` / `floss` | String extraction (FLOSS de-obfuscates stack/encrypted strings) |
| YARA 4.x | Pattern-based detection engine |
| Ghidra 11.3.1 | Disassembly and decompilation |
| MalwareBazaar (abuse.ch) | Sample source |
| Hybrid Analysis, Any.run | Public sandbox reports for cross-referenced dynamic behavior |

---

## Key findings (preview)

- **WannaCry** hides its primary payload in an encrypted `.rsrc` section (entropy 7.9998), and **dynamically resolves crypto APIs** at runtime to evade static import-based detection
- **NotPetya** is far more sophisticated: it includes hardcoded credential theft, network enumeration via DHCP, raw disk I/O for MBR overwrite, and embedded log-clearing commands
- Despite using the same EternalBlue exploit, the two families differ fundamentally in **intent**: WannaCry is genuine ransomware; NotPetya is a wiper with a ransomware veneer

Full analysis in the project report (linked in [`docs/`](docs/) when complete).

---

## References

- [MITRE ATT&CK — WannaCry (S0366)](https://attack.mitre.org/software/S0366/)
- [MITRE ATT&CK — NotPetya (S0368)](https://attack.mitre.org/software/S0368/)
- [US-CERT Alert TA17-132A — WannaCry](https://www.us-cert.gov/ncas/alerts/TA17-132A)
- [CrowdStrike — NotPetya Technical Analysis](https://www.crowdstrike.com/blog/notpetya-technical-analysis/)

Additional references in [`docs/references.md`](docs/references.md).

---

## License

MIT License — see [LICENSE](LICENSE).

For educational and research purposes only. The YARA rules are intended for defensive detection and threat hunting.
