// Staff Portal · © cmeproject. All rights reserved.
import { Fragment, type ReactNode } from "react";

// cmeprojects: shows an Assistant answer the way the AI wrote it (headings,
// **bold**, *italics*, bullet and numbered lists with indents, links), like a
// chat app. It builds the page from the text itself and never uses HTML from
// the answer, so nothing in an answer can run on the page.

type Item = { text: string; children: List | null };
type List = { ordered: boolean; items: Item[] };
type Block = { kind: "heading"; level: number; text: string } | { kind: "para"; text: string } | { kind: "list"; list: List };

const LIST_LINE = /^(\s*)([-*•]|\d+[.)])\s+(.*)$/;

function parse(source: string): Block[] {
  const lines = source.replace(/\r\n?/g, "\n").split("\n");
  const blocks: Block[] = [];
  let para: string[] = [];
  const flush = () => {
    if (para.length) blocks.push({ kind: "para", text: para.join(" ") });
    para = [];
  };

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const heading = line.match(/^\s*(#{1,4})\s+(.*)$/);
    if (!line.trim()) {
      flush();
    } else if (heading) {
      flush();
      blocks.push({ kind: "heading", level: heading[1].length, text: heading[2] });
    } else if (LIST_LINE.test(line)) {
      flush();
      // Collect the whole list, then nest items by their indent.
      const rows: { indent: number; ordered: boolean; text: string }[] = [];
      while (i < lines.length && (LIST_LINE.test(lines[i]) || (lines[i].trim() && /^\s{2,}/.test(lines[i]) && rows.length))) {
        const m = lines[i].match(LIST_LINE);
        if (m) rows.push({ indent: m[1].replace(/\t/g, "  ").length, ordered: /\d/.test(m[2]), text: m[3] });
        else rows[rows.length - 1].text += ` ${lines[i].trim()}`;
        i++;
      }
      i--;
      blocks.push({ kind: "list", list: nest(rows) });
    } else {
      para.push(line.trim());
    }
  }
  flush();
  return blocks;
}

function nest(rows: { indent: number; ordered: boolean; text: string }[]): List {
  const root: List = { ordered: rows[0]?.ordered ?? false, items: [] };
  const stack: { indent: number; list: List }[] = [{ indent: rows[0]?.indent ?? 0, list: root }];
  for (const row of rows) {
    while (stack.length > 1 && row.indent < stack[stack.length - 1].indent) stack.pop();
    let top = stack[stack.length - 1];
    if (row.indent > top.indent && top.list.items.length) {
      const parent = top.list.items[top.list.items.length - 1];
      parent.children = parent.children ?? { ordered: row.ordered, items: [] };
      stack.push({ indent: row.indent, list: parent.children });
      top = stack[stack.length - 1];
    }
    top.list.items.push({ text: row.text, children: null });
  }
  return root;
}

// **bold**, *italic* or _italic_, `code` and [links](https://…).
function inline(text: string): ReactNode[] {
  const out: ReactNode[] = [];
  const pattern = /(\*\*[^*]+\*\*|__[^_]+__|\*[^*\s][^*]*\*|_[^_\s][^_]*_|`[^`]+`|\[[^\]]+\]\((https?:\/\/[^)\s]+)\))/g;
  let last = 0;
  let key = 0;
  for (const m of text.matchAll(pattern)) {
    if (m.index! > last) out.push(text.slice(last, m.index));
    const t = m[0];
    if (t.startsWith("**") || t.startsWith("__")) out.push(<strong key={key++}>{t.slice(2, -2)}</strong>);
    else if (t.startsWith("`")) out.push(<code key={key++} className="rounded bg-page px-1 text-[0.95em]">{t.slice(1, -1)}</code>);
    else if (t.startsWith("[")) {
      const label = t.slice(1, t.indexOf("]"));
      out.push(
        <a key={key++} href={m[2]} target="_blank" rel="noopener noreferrer" className="text-brand underline">
          {label}
        </a>,
      );
    } else out.push(<em key={key++}>{t.slice(1, -1)}</em>);
    last = m.index! + t.length;
  }
  if (last < text.length) out.push(text.slice(last));
  return out;
}

function ListView({ list }: { list: List }) {
  const Tag = list.ordered ? "ol" : "ul";
  return (
    <Tag className={`flex flex-col gap-1 pl-6 ${list.ordered ? "list-decimal" : "list-disc"}`}>
      {list.items.map((item, i) => (
        <li key={i} className="pl-1">
          {inline(item.text)}
          {item.children ? (
            <div className="mt-1">
              <ListView list={item.children} />
            </div>
          ) : null}
        </li>
      ))}
    </Tag>
  );
}

export function AnswerText({ text }: { text: string }) {
  return (
    <div className="flex flex-col gap-3 leading-relaxed">
      {parse(text).map((b, i) => (
        <Fragment key={i}>
          {b.kind === "heading" ? (
            <p className={`font-semibold ${b.level <= 2 ? "text-lg" : "text-base"}`}>{inline(b.text)}</p>
          ) : b.kind === "list" ? (
            <ListView list={b.list} />
          ) : (
            <p>{inline(b.text)}</p>
          )}
        </Fragment>
      ))}
    </div>
  );
}
