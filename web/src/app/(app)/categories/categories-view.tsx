"use client";

import { Check, Pencil, Plus, Trash2 } from "lucide-react";
import { useMemo, useState, type FormEvent } from "react";
import { toast } from "sonner";

import { Field } from "@/components/common/field";
import { CATEGORY_ICONS, IconBadge, PALETTE } from "@/components/common/finance-icons";
import { PageHeader } from "@/components/common/page-header";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useCategories, useDeleteCategory, useSaveCategory } from "@/hooks/use-finance";
import { describeError } from "@/lib/api/describe";
import { ApiError } from "@/lib/api/errors";
import { useI18n } from "@/lib/i18n/provider";
import type { Category, CategoryType } from "@/lib/types";
import { cn } from "@/lib/utils";

const NONE = "none";

export function CategoriesView() {
  const { t, categoryLabel } = useI18n();
  const [type, setType] = useState<CategoryType>("expense");
  const [editing, setEditing] = useState<{ open: boolean; category?: Category | null }>({ open: false });
  const [deleting, setDeleting] = useState<Category | null>(null);
  const { data: categories, isLoading } = useCategories();

  const tree = useMemo(() => {
    const ofType = (categories ?? []).filter((c) => c.type === type);
    return ofType.filter((c) => !c.parent_id).map((parent) => ({ parent, children: ofType.filter((c) => c.parent_id === parent.id) }));
  }, [categories, type]);

  const row = (category: Category, child = false) => (
    <div key={category.id} className={cn("flex items-center gap-3 px-4 py-2.5", child && "ps-14")}>
      <IconBadge icon={CATEGORY_ICONS[category.icon ?? ""] ?? CATEGORY_ICONS.category} color={category.color} size={child ? 30 : 36} />
      <span className={cn("min-w-0 flex-1 truncate", !child && "font-medium")}>{categoryLabel(category)}</span>
      <Button variant="ghost" size="icon-sm" aria-label={t.common.edit} onClick={() => setEditing({ open: true, category })}>
        <Pencil />
      </Button>
      <Button variant="ghost" size="icon-sm" aria-label={t.common.delete} onClick={() => setDeleting(category)}>
        <Trash2 />
      </Button>
    </div>
  );

  return (
    <div className="space-y-6">
      <PageHeader
        title={t.categories.title}
        actions={
          <Button onClick={() => setEditing({ open: true, category: null })}>
            <Plus />
            {t.categories.add}
          </Button>
        }
      />
      <Tabs value={type} onValueChange={(v) => setType(v as CategoryType)}>
        <TabsList>
          <TabsTrigger value="expense">{t.transactions.expense}</TabsTrigger>
          <TabsTrigger value="income">{t.transactions.income}</TabsTrigger>
        </TabsList>
      </Tabs>
      <Card className="divide-y p-0">
        {isLoading
          ? Array.from({ length: 5 }, (_, i) => <Skeleton key={i} className="m-3 h-10" />)
          : tree.map(({ parent, children }) => (
              <div key={parent.id} className="py-1">
                {row(parent)}
                {children.map((child) => row(child, true))}
              </div>
            ))}
      </Card>

      <CategoryDialog
        open={editing.open}
        category={editing.category}
        type={type}
        categories={categories ?? []}
        onOpenChange={(open) => setEditing((e) => ({ ...e, open }))}
      />
      <DeleteCategoryDialog category={deleting} categories={categories ?? []} onClose={() => setDeleting(null)} />
    </div>
  );
}

function CategoryDialog({
  open,
  onOpenChange,
  category,
  type,
  categories,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  category?: Category | null;
  type: CategoryType;
  categories: Category[];
}) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <CategoryForm category={category} type={type} categories={categories} onDone={() => onOpenChange(false)} />
      </DialogContent>
    </Dialog>
  );
}

function CategoryForm({
  category,
  type,
  categories,
  onDone,
}: {
  category?: Category | null;
  type: CategoryType;
  categories: Category[];
  onDone: () => void;
}) {
  const { t, categoryLabel } = useI18n();
  const save = useSaveCategory();
  const effectiveType = category?.type ?? type;
  const displayName = category ? categoryLabel(category) : "";
  const [form, setForm] = useState(() => ({
    name: displayName,
    parent_id: category?.parent_id ?? NONE,
    color: category?.color ?? PALETTE[0],
    icon: category?.icon ?? "category",
  }));
  const [error, setError] = useState<string | undefined>();

  const hasChildren = !!category && categories.some((c) => c.parent_id === category.id);
  const parents = categories.filter((c) => c.type === effectiveType && !c.parent_id && c.id !== category?.id);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    const name = form.name.trim();
    if (!name) return setError(t.common.required);
    // Keep built-in categories localized unless the user actually renamed them.
    const renamed = !category || name !== displayName;
    try {
      await save.mutateAsync({
        id: category?.id,
        payload: {
          name: renamed ? name : category!.name,
          ...(category ? {} : { type: effectiveType }),
          parent_id: form.parent_id === NONE ? null : form.parent_id,
          color: form.color,
          icon: form.icon,
        },
      });
      toast.success(t.common.saved);
      onDone();
    } catch (e) {
      setError(e instanceof ApiError ? (Object.values(e.fieldErrors)[0]?.[0] ?? describeError(e, t)) : describeError(e, t));
    }
  }

  return (
    <>
      <DialogHeader>
        <DialogTitle>{category ? t.categories.edit : t.categories.add}</DialogTitle>
      </DialogHeader>
      <form id="category-form" onSubmit={onSubmit} className="space-y-4" noValidate>
        <Field id="category-name" label={t.categories.name} error={error}>
          <Input id="category-name" maxLength={60} value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
        </Field>
        {!hasChildren && (
          <Field id="parent" label={t.categories.parent}>
            <Select value={form.parent_id} onValueChange={(parent_id) => setForm({ ...form, parent_id })}>
              <SelectTrigger id="parent" className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value={NONE}>{t.categories.noParent}</SelectItem>
                {parents.map((p) => (
                  <SelectItem key={p.id} value={p.id}>
                    {categoryLabel(p)}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </Field>
        )}
        <div className="space-y-1.5">
          <Label>{t.categories.icon}</Label>
          <div className="grid grid-cols-8 gap-1.5">
            {Object.entries(CATEGORY_ICONS).map(([name, Icon]) => (
              <button
                key={name}
                type="button"
                aria-label={name}
                aria-pressed={form.icon === name}
                onClick={() => setForm({ ...form, icon: name })}
                className={cn(
                  "grid aspect-square place-items-center rounded-md border hover:bg-muted",
                  form.icon === name && "border-primary bg-primary/10 text-primary",
                )}
              >
                <Icon className="size-4" />
              </button>
            ))}
          </div>
        </div>
        <div className="space-y-1.5">
          <Label>{t.accounts.color}</Label>
          <div className="flex flex-wrap gap-2">
            {PALETTE.map((color) => (
              <button
                key={color}
                type="button"
                aria-label={color}
                aria-pressed={form.color === color}
                onClick={() => setForm({ ...form, color })}
                className="grid size-8 place-items-center rounded-full"
                style={{ background: color }}
              >
                {form.color === color && <Check className="size-4 text-white" />}
              </button>
            ))}
          </div>
        </div>
      </form>
      <DialogFooter>
        <Button variant="outline" onClick={onDone}>
          {t.common.cancel}
        </Button>
        <Button type="submit" form="category-form" disabled={save.isPending}>
          {t.common.save}
        </Button>
      </DialogFooter>
    </>
  );
}

function DeleteCategoryDialog({
  category,
  categories,
  onClose,
}: {
  category: Category | null;
  categories: Category[];
  onClose: () => void;
}) {
  const { t, categoryLabel } = useI18n();
  const remove = useDeleteCategory();
  // Remembered per category so reopening for another category starts clean.
  const [choice, setChoice] = useState<{ for: string | null; value: string }>({ for: null, value: NONE });
  const replacement = choice.for === category?.id ? choice.value : NONE;
  const setReplacement = (value: string) => setChoice({ for: category?.id ?? null, value });

  async function confirm() {
    if (!category) return;
    try {
      await remove.mutateAsync({ id: category.id, replacementId: replacement === NONE ? null : replacement });
      toast.success(t.common.deleted);
      onClose();
    } catch (e) {
      toast.error(describeError(e, t));
    }
  }

  return (
    <Dialog open={!!category} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{t.common.confirmDelete}</DialogTitle>
        </DialogHeader>
        <Field id="replacement" label={t.categories.moveTo}>
          <Select value={replacement} onValueChange={setReplacement}>
            <SelectTrigger id="replacement" className="w-full">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value={NONE}>{t.categories.leaveUncategorized}</SelectItem>
              {categories
                .filter((c) => category && c.type === category.type && c.id !== category.id)
                .map((c) => (
                  <SelectItem key={c.id} value={c.id}>
                    {categoryLabel(c)}
                  </SelectItem>
                ))}
            </SelectContent>
          </Select>
        </Field>
        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            {t.common.cancel}
          </Button>
          <Button variant="destructive" onClick={confirm} disabled={remove.isPending}>
            {t.common.delete}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
