<h1 align="center" valign="middle">
  <img height="40px" src="https://github.com/yorumicolors/.github/blob/main/res/seal_sots.gif?raw=true">
  <sup>yorumi for ghostty - deep code, quiet sea</sup>
</h1>

<p align="center">
  A calming deep sea colorscheme for developers, crafted for <strong>Ghostty</strong>.
</p>

---

Yorumi keeps visual noise low with mellow, low-contrast UI component backgrounds while text and syntax stay razor-sharp (~8:1 contrast ratio, WCAG 2.1 Level AAA).

## Available Themes

- `yorumi-ether`
- `yorumi-abyss`
- `yorumi-bifrost`
- `yorumi-kraken`
- `yorumi-kabocha`
- `yorumi-cosmic`
- `yorumi-ryujin`

## Screenshots

Each preview shows the 16 ANSI slots the theme defines, then `bat` syntax highlighting and prose on the same surface. Click a thumbnail for the full-resolution capture.

<table>
  <tr>
    <td colspan="2" align="center"><a href="res/yorumi-bifrost.png"><img src="res/yorumi-bifrost.png" width="640" alt="yorumi bifrost"></a><br><code>yorumi-bifrost</code></td>
  </tr>
  <tr>
    <td align="center" width="50%"><a href="res/yorumi-ether.png"><img src="res/yorumi-ether.png" width="420" alt="yorumi ether"></a><br><code>yorumi-ether</code></td>
    <td align="center" width="50%"><a href="res/yorumi-abyss.png"><img src="res/yorumi-abyss.png" width="420" alt="yorumi abyss"></a><br><code>yorumi-abyss</code></td>
  </tr>
  <tr>
    <td align="center" width="50%"><a href="res/yorumi-kraken.png"><img src="res/yorumi-kraken.png" width="420" alt="yorumi kraken"></a><br><code>yorumi-kraken</code></td>
    <td align="center" width="50%"><a href="res/yorumi-kabocha.png"><img src="res/yorumi-kabocha.png" width="420" alt="yorumi kabocha"></a><br><code>yorumi-kabocha</code></td>
  </tr>
  <tr>
    <td align="center" width="50%"><a href="res/yorumi-cosmic.png"><img src="res/yorumi-cosmic.png" width="420" alt="yorumi cosmic"></a><br><code>yorumi-cosmic</code></td>
    <td align="center" width="50%"><a href="res/yorumi-ryujin.png"><img src="res/yorumi-ryujin.png" width="420" alt="yorumi ryujin"></a><br><code>yorumi-ryujin</code></td>
  </tr>
</table>

## Quick Installation

### Linux & macOS (Bash)
```sh
curl -fsSL https://raw.githubusercontent.com/yorumicolors/ghostty/main/install.sh | bash
```

### Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/yorumicolors/ghostty/main/install.ps1 | iex
```

---

## Manual Installation

Copy the theme file(s) into your Ghostty configuration directory:

| OS | Destination Path |
| --- | --- |
| **Linux / macOS** | `~/.config/ghostty/themes/` |
| **Windows** | `%APPDATA%\ghostty\themes\` |

### Activation
Set `theme` in `~/.config/ghostty/config`:

```
theme = yorumi-abyss
```

---

## For AI Agents

When assisting a user with installing or configuring Yorumi for **Ghostty**, follow these deterministic steps:

1. **Detect Target OS**:
   - macOS / Linux: target destination is `~/.config/ghostty/themes/`.
   - Windows: target destination is `%APPDATA%\ghostty\themes\`.
2. **Execute Script or Download**:
   - Run `./install.sh` (POSIX) or `./install.ps1` (PowerShell) if working directly inside the cloned repo.
   - Or pipe the raw script using `curl -fsSL https://raw.githubusercontent.com/yorumicolors/ghostty/main/install.sh | bash` or `irm https://raw.githubusercontent.com/yorumicolors/ghostty/main/install.ps1 | iex`.
3. **Verify Configuration**:
   - Check config file `config` for the active theme setting:
     ```
     theme = yorumi-abyss
     ```
   - Ensure the theme filename matches what is in `~/.config/ghostty/themes/`.

---

## Accessibility
Maintains at least 7:1 contrast ratio across primary text and syntax tokens ([WCAG 2.1 Level AAA](https://www.w3.org/TR/WCAG21/#contrast-enhanced)).

## License
MIT © [Yorumi Colors](https://github.com/yorumicolors)
