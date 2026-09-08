/**
 * Modal Editor - vim-style modal editing for the pi prompt editor.
 *
 * Modes:
 *   - INSERT (default): type normally. `Escape` or `jk` -> NORMAL.
 *   - NORMAL: vim motions/operators. `i a o ...` -> INSERT. `v`/`V` -> VISUAL.
 *   - VISUAL / V-LINE: select then operate (y d c x). `Escape`/`v` -> NORMAL.
 *
 * Mode feedback: current mode is shown in the footer/bottom status bar and on
 * the editor border. In visual mode it also shows the live selection size,
 * e.g. "-- VISUAL (12) --".
 *
 * Visual-mode caveat: pi's base Editor exposes no selection/highlight API
 * (getText/getLines/getCursor/setText/insertTextAtCursor only), so the selected
 * range is NOT highlighted. The cursor still moves visibly and the operators
 * act on the anchor..cursor range, with the selection size shown in the footer.
 *
 * Safety wiring for this setup:
 *   - `Escape` NEVER aborts the agent.
 *   - `jk` (quick, in INSERT) -> NORMAL (matches `inoremap jk <Esc>`).
 *   - `Ctrl+C` passes through -> `app.interrupt` to cancel the current op.
 *
 * NORMAL keys: h j k l  w b e  0 ^ $  gg G  D(down10) U(up10)
 *              i a A I  o O  x  u  p  v V
 *              dd cc  d/c + {w,b,e,$,0,^}
 * VISUAL keys: motions + y d c x p, o(swap ends), v/V/Escape to exit
 * note: `r` (redo in the user's nvim) is a no-op; pi has no redo primitive.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import { CustomEditor, type ExtensionAPI, type ExtensionContext, getAgentDir } from "@earendil-works/pi-coding-agent";
import { matchesKey, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

// ---- Global, cross-session prompt history ------------------------------
// Persisted as JSONL (one JSON-encoded string per line) in the pi config dir,
// so arrow-up recalls prompts from every past session and project.
const HISTORY_FILE = path.join(getAgentDir(), "prompt-history.jsonl");
const HISTORY_MAX = 5000;

function loadHistory(): string[] {
	try {
		const lines = fs.readFileSync(HISTORY_FILE, "utf8").split("\n").filter(Boolean);
		const out: string[] = [];
		for (const l of lines) {
			try {
				const v = JSON.parse(l);
				if (typeof v === "string" && v.trim()) out.push(v);
			} catch {
				/* skip malformed line */
			}
		}
		// Trim the file if it has grown well past the cap.
		if (out.length > Math.floor(HISTORY_MAX * 1.2)) {
			const kept = out.slice(-HISTORY_MAX);
			try {
				fs.writeFileSync(HISTORY_FILE, kept.map((t) => JSON.stringify(t)).join("\n") + "\n");
			} catch {
				/* best effort */
			}
			return kept;
		}
		return out.slice(-HISTORY_MAX);
	} catch {
		return [];
	}
}

function appendHistory(text: string): void {
	try {
		fs.mkdirSync(path.dirname(HISTORY_FILE), { recursive: true });
		fs.appendFileSync(HISTORY_FILE, JSON.stringify(text) + "\n");
	} catch {
		/* best effort */
	}
}

const SEQ = {
	left: "\x1b[D",
	right: "\x1b[C",
	up: "\x1b[A",
	down: "\x1b[B",
	lineStart: "\x01",
	lineEnd: "\x05",
	deleteCharFwd: "\x1b[3~",
	deleteCharBack: "\x7f",
	killToLineEnd: "\x0b",
	killToLineStart: "\x15",
	deleteWordBack: "\x17",
	deleteWordFwd: "\x1bd",
	wordLeft: "\x1bb",
	wordRight: "\x1bf",
	newline: "\x0a",
	undo: "\x1f",
} as const;

const JK_TIMEOUT_MS = 500;
const BIG_JUMP = 10;

type Mode = "normal" | "insert" | "visual" | "visual-line";

interface Status {
	text: string;
	color: "success" | "warning" | "accent";
}

class ModalEditor extends CustomEditor {
	private mode: Mode = "insert";
	private pending: string | null = null;
	private jPending = false;
	private jTime = 0;
	private anchor = 0; // selection anchor offset (visual modes)
	private register = "";
	private registerLinewise = false;

	constructor(
		tui: ConstructorParameters<typeof CustomEditor>[0],
		theme: ConstructorParameters<typeof CustomEditor>[1],
		kb: ConstructorParameters<typeof CustomEditor>[2],
		history: string[],
		private readonly onStatus: (s: Status) => void,
	) {
		super(tui, theme, kb);
		// Seed the editor's up/down history with the global prompt history
		// (oldest first, so arrow-up walks backwards through recent prompts).
		for (const entry of history) this.addToHistory(entry);
		this.emitStatus();
	}

	// ---- offsets --------------------------------------------------------

	private lineLengths(): number[] {
		return this.getLines().map((l) => l.length);
	}

	private curOffset(): number {
		const { line, col } = this.getCursor();
		const lens = this.lineLengths();
		let off = 0;
		for (let i = 0; i < line; i++) off += lens[i] + 1; // +1 for newline
		return off + col;
	}

	private moveToOffset(target: number): void {
		const diff = target - this.curOffset();
		if (diff > 0) for (let i = 0; i < diff; i++) super.handleInput(SEQ.right);
		else for (let i = 0; i < -diff; i++) super.handleInput(SEQ.left);
	}

	private selectionRange(): { a: number; b: number } {
		const cur = this.curOffset();
		let a = Math.min(this.anchor, cur);
		let b = Math.max(this.anchor, cur);
		if (this.mode === "visual-line") {
			const lens = this.lineLengths();
			const text = this.getText();
			// expand to whole lines
			let startLine = 0;
			let acc = 0;
			for (let i = 0; i < lens.length; i++) {
				if (a >= acc && a <= acc + lens[i]) {
					startLine = i;
					break;
				}
				acc += lens[i] + 1;
			}
			let endLine = startLine;
			acc = 0;
			for (let i = 0; i < lens.length; i++) {
				if (b >= acc && b <= acc + lens[i]) {
					endLine = i;
					break;
				}
				acc += lens[i] + 1;
			}
			let sa = 0;
			for (let i = 0; i < startLine; i++) sa += lens[i] + 1;
			let sb = 0;
			for (let i = 0; i < endLine; i++) sb += lens[i] + 1;
			sb += lens[endLine];
			if (sb < text.length) sb += 1; // include trailing newline
			return { a: sa, b: sb };
		}
		// charwise: include the char under the higher endpoint
		b = Math.min(b + 1, this.getText().length);
		return { a, b };
	}

	private deleteRange(a: number, b: number): void {
		if (b <= a) return;
		this.moveToOffset(b);
		for (let i = 0; i < b - a; i++) super.handleInput(SEQ.deleteCharBack);
	}

	private pasteRegister(): void {
		if (!this.register) return;
		if (this.registerLinewise) {
			super.handleInput(SEQ.lineEnd);
			super.handleInput(SEQ.newline);
			this.insertTextAtCursor(this.register.replace(/\n$/, ""));
		} else {
			this.insertTextAtCursor(this.register);
		}
	}

	// ---- status ---------------------------------------------------------

	private emitStatus(): void {
		this.onStatus(this.statusFor());
	}

	private statusFor(): Status {
		switch (this.mode) {
			case "insert":
				return { text: "-- INSERT --", color: "success" };
			case "normal":
				return { text: "-- NORMAL --", color: "warning" };
			case "visual": {
				const { a, b } = this.selectionRange();
				return { text: `-- VISUAL (${b - a}) --`, color: "accent" };
			}
			case "visual-line": {
				const { a, b } = this.selectionRange();
				const lines = this.getText().slice(a, b).split("\n").length;
				return { text: `-- V-LINE (${lines}) --`, color: "accent" };
			}
		}
	}

	private setMode(mode: Mode): void {
		this.mode = mode;
		this.pending = null;
		this.emitStatus();
	}

	private enterVisual(mode: "visual" | "visual-line"): void {
		this.anchor = this.curOffset();
		this.setMode(mode);
	}

	// ---- motions (shared by normal + visual) ---------------------------

	private repeat(seq: string, n: number): void {
		for (let i = 0; i < n; i++) super.handleInput(seq);
	}

	/** Perform a cursor motion. Returns true if `data` was a motion key. */
	private doMotion(data: string): boolean {
		switch (data) {
			case "h":
				super.handleInput(SEQ.left);
				return true;
			case "l":
				super.handleInput(SEQ.right);
				return true;
			case "j":
				super.handleInput(SEQ.down);
				return true;
			case "k":
				super.handleInput(SEQ.up);
				return true;
			case "w":
			case "e":
				super.handleInput(SEQ.wordRight);
				return true;
			case "b":
				super.handleInput(SEQ.wordLeft);
				return true;
			case "0":
			case "^":
				super.handleInput(SEQ.lineStart);
				return true;
			case "$":
				super.handleInput(SEQ.lineEnd);
				return true;
			case "D":
				this.repeat(SEQ.down, BIG_JUMP);
				return true;
			case "U":
				this.repeat(SEQ.up, BIG_JUMP);
				return true;
			case "G":
				this.repeat(SEQ.down, 200);
				super.handleInput(SEQ.lineEnd);
				return true;
			default:
				return false;
		}
	}

	private applyOperator(op: string, motion: string): boolean {
		switch (motion) {
			case "$":
				super.handleInput(SEQ.killToLineEnd);
				break;
			case "0":
			case "^":
				super.handleInput(SEQ.killToLineStart);
				break;
			case "w":
			case "e":
				super.handleInput(SEQ.deleteWordFwd);
				break;
			case "b":
				super.handleInput(SEQ.deleteWordBack);
				break;
			default:
				return false;
		}
		if (op === "c") this.setMode("insert");
		return true;
	}

	// ---- input ----------------------------------------------------------

	handleInput(data: string): void {
		if (data === "\x03") {
			super.handleInput(data);
			return;
		}

		if (matchesKey(data, "escape")) {
			this.setMode("normal");
			return;
		}

		if (this.mode === "insert") {
			if (data === "k" && this.jPending && Date.now() - this.jTime < JK_TIMEOUT_MS) {
				this.jPending = false;
				super.handleInput(SEQ.deleteCharBack);
				this.setMode("normal");
				return;
			}
			this.jPending = data === "j";
			this.jTime = Date.now();
			super.handleInput(data);
			return;
		}

		// pass through control sequences in non-insert modes
		if (data.length === 1 && data.charCodeAt(0) < 32) {
			super.handleInput(data);
			return;
		}

		if (this.mode === "visual" || this.mode === "visual-line") {
			this.handleVisual(data);
			return;
		}

		// ---- NORMAL ----
		if (this.pending) {
			const op = this.pending;
			this.pending = null;
			if (op === "g" && data === "g") {
				this.repeat(SEQ.up, 200);
				super.handleInput(SEQ.lineStart);
				return;
			}
			if ((op === "d" || op === "c") && data === op) {
				super.handleInput(SEQ.lineStart);
				super.handleInput(SEQ.killToLineEnd);
				if (op === "d") super.handleInput(SEQ.deleteCharFwd);
				else this.setMode("insert");
				return;
			}
			if ((op === "d" || op === "c") && this.applyOperator(op, data)) return;
			return;
		}

		if (this.doMotion(data)) return;

		switch (data) {
			case "i":
				this.setMode("insert");
				return;
			case "a":
				super.handleInput(SEQ.right);
				this.setMode("insert");
				return;
			case "A":
				super.handleInput(SEQ.lineEnd);
				this.setMode("insert");
				return;
			case "I":
				super.handleInput(SEQ.lineStart);
				this.setMode("insert");
				return;
			case "o":
				super.handleInput(SEQ.lineEnd);
				super.handleInput(SEQ.newline);
				this.setMode("insert");
				return;
			case "O":
				super.handleInput(SEQ.lineStart);
				super.handleInput(SEQ.newline);
				super.handleInput(SEQ.up);
				this.setMode("insert");
				return;
			case "x":
				super.handleInput(SEQ.deleteCharFwd);
				return;
			case "u":
				super.handleInput(SEQ.undo);
				return;
			case "p":
				this.pasteRegister();
				return;
			case "v":
				this.enterVisual("visual");
				return;
			case "V":
				this.enterVisual("visual-line");
				return;
			case "d":
			case "c":
			case "g":
				this.pending = data;
				return;
			default:
				return;
		}
	}

	private handleVisual(data: string): void {
		// toggle / exit
		if (data === "v") {
			if (this.mode === "visual") this.setMode("normal");
			else this.setMode("visual");
			return;
		}
		if (data === "V") {
			if (this.mode === "visual-line") this.setMode("normal");
			else this.setMode("visual-line");
			return;
		}
		if (data === "o") {
			// swap cursor and anchor
			const cur = this.curOffset();
			const oldAnchor = this.anchor;
			this.anchor = cur;
			this.moveToOffset(oldAnchor);
			this.emitStatus();
			return;
		}

		// motions update the selection
		if (this.doMotion(data)) {
			this.emitStatus();
			return;
		}

		// operators
		const linewise = this.mode === "visual-line";
		if (data === "y" || data === "d" || data === "c" || data === "x") {
			const { a, b } = this.selectionRange();
			this.register = this.getText().slice(a, b);
			this.registerLinewise = linewise;
			if (data === "y") {
				this.moveToOffset(a);
				this.setMode("normal");
			} else if (data === "d" || data === "x") {
				this.deleteRange(a, b);
				this.setMode("normal");
			} else {
				this.deleteRange(a, b);
				this.setMode("insert");
			}
			return;
		}
		if (data === "p") {
			const { a, b } = this.selectionRange();
			this.deleteRange(a, b);
			this.pasteRegister();
			this.setMode("normal");
			return;
		}
	}

	render(width: number): string[] {
		const lines = super.render(width);
		if (lines.length === 0) return lines;
		const label =
			this.mode === "insert"
				? " INSERT "
				: this.mode === "normal"
					? " NORMAL "
					: this.mode === "visual"
						? " VISUAL "
						: " V-LINE ";
		const last = lines.length - 1;
		if (visibleWidth(lines[last]!) >= label.length) {
			lines[last] = truncateToWidth(lines[last]!, width - label.length, "") + label;
		}
		return lines;
	}
}

export default function (pi: ExtensionAPI) {
	let lastRecorded = "";

	pi.on("session_start", (_event, ctx: ExtensionContext) => {
		const history = loadHistory();
		lastRecorded = history.length > 0 ? history[history.length - 1] : "";
		ctx.ui.setEditorComponent(
			(tui, theme, kb) =>
				new ModalEditor(tui, theme, kb, history, (s) =>
					ctx.ui.setStatus("vim-mode", ctx.ui.theme.fg(s.color, s.text)),
				),
		);
	});

	// Record every interactively submitted prompt to the global history file.
	pi.on("input", (event) => {
		if (event.source !== "interactive") return;
		const text = event.text ?? "";
		if (!text.trim() || text === lastRecorded) return;
		lastRecorded = text;
		appendHistory(text);
	});
}
