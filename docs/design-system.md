# Norte — Design System (inspirado no Claude Code)

> Guia visual obrigatório para toda a camada `presentation/`. A estética é a do **Claude Code**:
> terminal moderno, fundo escuro quente, acento coral/laranja, tipografia monoespaçada para dados técnicos,
> interface densa porém calma. Este documento define tokens que a IA executora deve implementar como
> `ThemeData`/`ThemeExtension` na Sprint 00 e usar em todas as telas.

---

## 1. Princípios visuais

1. **Terminal-first:** a UI lembra um terminal refinado — superfícies planas, cantos levemente arredondados (8px), sem sombras pesadas, separadores de 1px.
2. **Um único acento:** o coral `#D97757` é o único acento de marca. Estados (sucesso/erro/aviso) têm cores próprias e discretas.
3. **Dark é o tema padrão.** Light existe e usa o marfim quente da paleta Anthropic.
4. **Mono para dados, sans para prosa:** issue keys (`PROJ-123`), status, timestamps, transcripts e comandos usam fonte mono; títulos e textos correntes usam sans.
5. **Densidade calma:** espaçamento em escala de 4px; nada de gradientes, glassmorphism ou animações decorativas. Animações apenas funcionais (≤200ms, curvas padrão do Material).

## 2. Paleta de cores (tokens)

### 2.1 Tema escuro (padrão)

| Token | Hex | Uso |
|---|---|---|
| `bg` | `#1F1E1D` | Fundo principal do app |
| `surface` | `#262624` | Cards, campos, painéis |
| `surfaceRaised` | `#30302E` | Hover, itens selecionados, modais |
| `border` | `#3E3E3A` | Separadores e bordas de 1px |
| `textPrimary` | `#F5F4EF` | Texto principal |
| `textSecondary` | `#A8A79E` | Texto de apoio, metadados |
| `textMuted` | `#6E6D66` | Placeholders, desabilitado |
| `accent` | `#D97757` | Botões primários, links, foco, ícone ativo |
| `accentHover` | `#E08B6D` | Hover/pressed do acento |
| `accentSubtle` | `#3A2A22` | Fundo de chips/realces com acento |
| `success` | `#7BAE7F` | Task concluída, sync ok |
| `warning` | `#D9A45B` | Divergência local×Jira, confidence baixa |
| `error` | `#C4553D` | Falhas, ações destrutivas |
| `info` | `#6A9BCC` | Estados informativos, links Jira |

### 2.2 Tema claro

| Token | Hex | Uso |
|---|---|---|
| `bg` | `#FAF9F5` | Fundo principal (marfim) |
| `surface` | `#FFFFFF` | Cards, campos |
| `surfaceRaised` | `#F0EEE6` | Hover, selecionados |
| `border` | `#E3E1D9` | Separadores |
| `textPrimary` | `#191919` | Texto principal |
| `textSecondary` | `#5E5D59` | Texto de apoio |
| `textMuted` | `#9B9A94` | Placeholders |
| `accent` | `#C2603F` | Acento (coral escurecido p/ contraste AA) |
| `accentHover` | `#D97757` | Hover |
| `accentSubtle` | `#F6E3DB` | Chips/realces |
| `success` | `#4E7D52` | — |
| `warning` | `#A97B2F` | — |
| `error` | `#B03A24` | — |
| `info` | `#3E6C99` | — |

**Regra:** todo par texto/fundo deve atingir contraste **WCAG AA (≥4.5:1)** para texto normal. Isso é verificado por teste (S00-UT-04).

## 3. Tipografia

| Papel | Fonte | Tamanho/peso | Uso |
|---|---|---|---|
| `display` | Sans (Inter ou system) | 24 / w600 | Título de tela |
| `title` | Sans | 17 / w600 | Título de card/section |
| `body` | Sans | 14.5 / w400 | Texto corrente |
| `caption` | Sans | 12 / w400, `textSecondary` | Metadados, timestamps relativos |
| `mono` | JetBrains Mono (bundled) | 13 / w400 | Issue keys, status, transcript, comandos de voz reconhecidos |
| `monoSmall` | JetBrains Mono | 11 / w500, uppercase, letter-spacing 0.6 | Badges de status |

## 4. Componentes padrão

Implementados em `presentation/shared/` na Sprint 00 e reutilizados em todo o app:

| Componente | Especificação |
|---|---|
| `NorteButton` | Primário: fundo `accent`, texto `#FFFFFF`, radius 8, altura 40. Secundário: borda 1px `border`, texto `textPrimary`. Destrutivo: fundo `error`. Estados: hover (`accentHover`), disabled (50% opacity), loading (spinner 16px substitui label) |
| `NorteCard` | Fundo `surface`, borda 1px `border`, radius 8, padding 16 |
| `StatusBadge` | `monoSmall` + ponto de 6px à esquerda. Cores: todo=`textMuted`, inProgress=`info`, done=`success`, blocked=`error` |
| `JiraChip` | Fonte `mono`, fundo `accentSubtle`, texto `accent`, prefixo do issueKey (ex.: `PROJ-123`); tap abre ação de link |
| `DivergenceBanner` | Fundo `warning` a 15% de opacidade, borda esquerda 3px `warning`, texto explicando status local vs. Jira + dois botões de decisão (RN-02) |
| `VoiceOverlay` | Painel inferior estilo "prompt de terminal": fundo `surface`, prefixo `❯` em `accent`, transcript parcial em `mono` `textSecondary`, committed em `textPrimary` |
| `ConfirmSheet` | Bottom sheet usado para confirmação de intents (RN-04): mostra a ação interpretada em `mono`, confidence como barra, botões Confirmar (`accent`) / Cancelar |
| `EmptyState` | Ícone 32px `textMuted` + frase curta + ação primária opcional |

## 5. Layout e navegação

- **Mobile:** bottom navigation com 4 destinos — Tarefas, Reuniões, Lembretes, Ajustes. Botão de voz flutuante central (círculo `accent`, ícone mic) presente em todas as abas.
- **Windows/desktop (≥ 900px):** navigation rail à esquerda (72px colapsado), conteúdo em coluna central máx. 840px. Botão de voz no rail.
- Grid de espaçamento: múltiplos de 4 (4/8/12/16/24/32). Padding padrão de tela: 16 (mobile) / 24 (desktop).
- Ícones: `lucide_icons` (traço 1.5px, consistente com a estética de terminal).

## 6. Estados obrigatórios de toda tela

Toda tela implementa e testa (golden) os 4 estados: **loading** (skeleton, nunca spinner de tela cheia), **vazio** (`EmptyState`), **erro** (mensagem + retry) e **conteúdo**.

## 7. Implementação (Sprint 00)

- Tokens em `presentation/shared/theme/norte_colors.dart` como `ThemeExtension<NorteColors>` (dark + light).
- Tipografia em `norte_typography.dart`; componentes em `presentation/shared/widgets/`.
- **Proibido** usar cor literal (`Color(0xFF...)`) fora dos arquivos de tema — gate verificado por grep no G5/S00.
