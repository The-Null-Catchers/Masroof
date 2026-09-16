"use client";

import { X } from "lucide-react";
import { useState, type KeyboardEvent } from "react";

import { useI18n } from "@/lib/i18n/provider";

export function TagInput({
  id,
  value,
  onChange,
  suggestions = [],
}: {
  id: string;
  value: string[];
  onChange: (tags: string[]) => void;
  suggestions?: string[];
}) {
  const { t } = useI18n();
  const [draft, setDraft] = useState("");

  function commit(raw: string) {
    const name = raw.trim().replace(/\s+/g, " ").slice(0, 40);
    if (!name || value.some((tag) => tag.toLowerCase() === name.toLowerCase()) || value.length >= 10) return setDraft("");
    onChange([...value, name]);
    setDraft("");
  }

  function onKeyDown(event: KeyboardEvent<HTMLInputElement>) {
    if (event.key === "Enter" || event.key === "," || event.key === "،") {
      event.preventDefault();
      commit(draft);
    } else if (event.key === "Backspace" && !draft && value.length) {
      onChange(value.slice(0, -1));
    }
  }

  return (
    <div className="flex min-h-9 flex-wrap items-center gap-1.5 rounded-lg border border-input px-2 py-1.5 focus-within:border-ring focus-within:ring-3 focus-within:ring-ring/50">
      {value.map((tag) => (
        <span key={tag} className="inline-flex items-center gap-1 rounded-md bg-secondary px-2 py-0.5 text-xs text-secondary-foreground">
          {tag}
          <button type="button" aria-label={`${t.common.delete} ${tag}`} onClick={() => onChange(value.filter((v) => v !== tag))}>
            <X className="size-3" />
          </button>
        </span>
      ))}
      <input
        id={id}
        list={`${id}-suggestions`}
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        onKeyDown={onKeyDown}
        onBlur={() => commit(draft)}
        placeholder={value.length ? "" : t.transactions.tagsHint}
        className="min-w-24 flex-1 bg-transparent text-sm outline-none placeholder:text-muted-foreground"
      />
      <datalist id={`${id}-suggestions`}>
        {suggestions.map((s) => (
          <option key={s} value={s} />
        ))}
      </datalist>
    </div>
  );
}
