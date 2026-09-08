/**
 * Web tools - give the model web search + page fetching.
 *
 * Tools:
 *   - web_search(query, count?): search the web.
 *       Prefers the Brave Search API when BRAVE_API_KEY (or BRAVE_SEARCH_API_KEY)
 *       is set (structured, reliable). Falls back to a keyless DuckDuckGo HTML
 *       scrape when no key is present.
 *   - web_fetch(url): fetch a page and return readable text (HTML stripped).
 *
 * All requests are abortable (Esc / ctrl+c) and time-limited.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const DEFAULT_TIMEOUT_MS = 15000;
const MAX_FETCH_BYTES = 2_000_000; // cap download size
const MAX_TEXT_CHARS = 8000; // cap text returned to the model
const USER_AGENT =
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0 Safari/537.36";

interface SearchResult {
	title: string;
	url: string;
	snippet: string;
}

function braveApiKey(): string | undefined {
	return process.env.BRAVE_API_KEY || process.env.BRAVE_SEARCH_API_KEY || undefined;
}

// Merge the caller's abort signal with a timeout.
function withTimeout(signal: AbortSignal | undefined, ms: number): { signal: AbortSignal; done: () => void } {
	const ctrl = new AbortController();
	const onAbort = () => ctrl.abort();
	if (signal) {
		if (signal.aborted) ctrl.abort();
		else signal.addEventListener("abort", onAbort, { once: true });
	}
	const timer = setTimeout(() => ctrl.abort(), ms);
	return {
		signal: ctrl.signal,
		done: () => {
			clearTimeout(timer);
			if (signal) signal.removeEventListener("abort", onAbort);
		},
	};
}

function decodeEntities(s: string): string {
	return s
		.replace(/&amp;/g, "&")
		.replace(/&lt;/g, "<")
		.replace(/&gt;/g, ">")
		.replace(/&quot;/g, '"')
		.replace(/&#39;/g, "'")
		.replace(/&#x27;/gi, "'")
		.replace(/&nbsp;/g, " ")
		.replace(/&#(\d+);/g, (_, n) => String.fromCharCode(Number(n)));
}

function stripTags(html: string): string {
	return decodeEntities(
		html
			.replace(/<script[\s\S]*?<\/script>/gi, " ")
			.replace(/<style[\s\S]*?<\/style>/gi, " ")
			.replace(/<noscript[\s\S]*?<\/noscript>/gi, " ")
			.replace(/<!--[\s\S]*?-->/g, " ")
			.replace(/<\/(p|div|section|article|li|h[1-6]|tr|br)>/gi, "\n")
			.replace(/<br\s*\/?>/gi, "\n")
			.replace(/<[^>]+>/g, " "),
	)
		.replace(/[ \t]+/g, " ")
		.replace(/\n[ \t]+/g, "\n")
		.replace(/\n{3,}/g, "\n\n")
		.trim();
}

async function readBody(res: Response, signal: AbortSignal): Promise<string> {
	if (!res.body) return await res.text();
	const reader = res.body.getReader();
	const chunks: Uint8Array[] = [];
	let total = 0;
	while (true) {
		if (signal.aborted) {
			await reader.cancel();
			break;
		}
		const { done, value } = await reader.read();
		if (done) break;
		if (value) {
			chunks.push(value);
			total += value.length;
			if (total > MAX_FETCH_BYTES) {
				await reader.cancel();
				break;
			}
		}
	}
	return Buffer.concat(chunks).toString("utf8");
}

async function braveSearch(query: string, count: number, signal: AbortSignal): Promise<SearchResult[]> {
	const url = `https://api.search.brave.com/res/v1/web/search?q=${encodeURIComponent(query)}&count=${count}`;
	const res = await fetch(url, {
		headers: {
			Accept: "application/json",
			"Accept-Encoding": "gzip",
			"X-Subscription-Token": braveApiKey() as string,
		},
		signal,
	});
	if (!res.ok) throw new Error(`Brave API ${res.status}: ${(await res.text()).slice(0, 200)}`);
	const data = (await res.json()) as { web?: { results?: Array<{ title: string; url: string; description?: string }> } };
	return (data.web?.results ?? []).slice(0, count).map((r) => ({
		title: decodeEntities(r.title ?? ""),
		url: r.url,
		snippet: stripTags(r.description ?? ""),
	}));
}

async function duckSearch(query: string, count: number, signal: AbortSignal): Promise<SearchResult[]> {
	const url = `https://html.duckduckgo.com/html/?q=${encodeURIComponent(query)}`;
	const res = await fetch(url, { headers: { "User-Agent": USER_AGENT }, signal });
	if (!res.ok) throw new Error(`DuckDuckGo ${res.status}`);
	const html = await readBody(res, signal);
	const results: SearchResult[] = [];
	const linkRe = /<a[^>]*class="result__a"[^>]*href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/gi;
	const snippetRe = /<a[^>]*class="result__snippet"[^>]*>([\s\S]*?)<\/a>/gi;
	const snippets: string[] = [];
	for (const m of html.matchAll(snippetRe)) snippets.push(stripTags(m[1]));
	let i = 0;
	for (const m of html.matchAll(linkRe)) {
		let href = decodeEntities(m[1]);
		// DuckDuckGo wraps targets in a redirect; unwrap uddg=
		const uddg = href.match(/[?&]uddg=([^&]+)/);
		if (uddg) href = decodeURIComponent(uddg[1]);
		results.push({ title: stripTags(m[2]), url: href, snippet: snippets[i] ?? "" });
		if (++i >= count) break;
	}
	return results;
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "web_search",
		label: "Web Search",
		description:
			"Search the web for up-to-date information, docs, or facts. Returns a ranked list of {title, url, snippet}. Use web_fetch to read a result in full.",
		parameters: Type.Object({
			query: Type.String({ description: "Search query" }),
			count: Type.Optional(Type.Number({ description: "Number of results (default 5, max 10)" })),
		}),
		async execute(_id, params, signal, _onUpdate, _ctx) {
			const count = Math.max(1, Math.min(10, params.count ?? 5));
			const { signal: sig, done } = withTimeout(signal, DEFAULT_TIMEOUT_MS);
			try {
				const useBrave = Boolean(braveApiKey());
				const results = useBrave
					? await braveSearch(params.query, count, sig)
					: await duckSearch(params.query, count, sig);
				if (results.length === 0) {
					return { content: [{ type: "text", text: `No results for: ${params.query}` }], details: {} };
				}
				const text = results
					.map((r, i) => `${i + 1}. ${r.title}\n   ${r.url}\n   ${r.snippet}`.trimEnd())
					.join("\n\n");
				const src = useBrave ? "brave" : "duckduckgo";
				return {
					content: [{ type: "text", text: `Search results (${src}) for "${params.query}":\n\n${text}` }],
					details: { source: src, results },
				};
			} catch (err) {
				const msg = err instanceof Error ? err.message : String(err);
				return { content: [{ type: "text", text: `web_search failed: ${msg}` }], details: {}, isError: true };
			} finally {
				done();
			}
		},
	});

	pi.registerTool({
		name: "web_fetch",
		label: "Web Fetch",
		description:
			"Fetch a URL and return its readable text content (HTML stripped, truncated). Use after web_search to read a page.",
		parameters: Type.Object({
			url: Type.String({ description: "The absolute URL to fetch (http/https)" }),
		}),
		async execute(_id, params, signal, _onUpdate, _ctx) {
			if (!/^https?:\/\//i.test(params.url)) {
				return { content: [{ type: "text", text: "web_fetch: url must start with http:// or https://" }], details: {}, isError: true };
			}
			const { signal: sig, done } = withTimeout(signal, DEFAULT_TIMEOUT_MS);
			try {
				const res = await fetch(params.url, { headers: { "User-Agent": USER_AGENT }, redirect: "follow", signal: sig });
				if (!res.ok) {
					return { content: [{ type: "text", text: `web_fetch: HTTP ${res.status} for ${params.url}` }], details: {}, isError: true };
				}
				const ctype = res.headers.get("content-type") ?? "";
				const raw = await readBody(res, sig);
				const body = /html/i.test(ctype) || /^\s*</.test(raw) ? stripTags(raw) : raw.trim();
				const truncated = body.length > MAX_TEXT_CHARS;
				const text = truncated ? `${body.slice(0, MAX_TEXT_CHARS)}\n\n[truncated ${body.length - MAX_TEXT_CHARS} chars]` : body;
				return {
					content: [{ type: "text", text: `${params.url}\n\n${text}` }],
					details: { url: params.url, contentType: ctype, truncated },
				};
			} catch (err) {
				const msg = err instanceof Error ? err.message : String(err);
				return { content: [{ type: "text", text: `web_fetch failed: ${msg}` }], details: {}, isError: true };
			} finally {
				done();
			}
		},
	});
}
