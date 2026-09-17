"use client";

import { Camera, Loader2, ScanLine, Upload } from "lucide-react";
import { useRef, useState } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { useAccounts, useDeleteReceipt, useReceipt, useUploadReceipt } from "@/hooks/use-finance";
import { describeError } from "@/lib/api/describe";
import { useI18n } from "@/lib/i18n/provider";
import type { Receipt } from "@/lib/types";

import type { TransactionDraft } from "./transaction-dialog";

const MAX_BYTES = 10 * 1024 * 1024;
const ACCEPT = "image/jpeg,image/png,image/webp";

/** Maps OCR output onto the transaction form; the user verifies before saving. */
export function receiptDraft(receipt: Receipt, accountId?: string): TransactionDraft {
  const x = receipt.extracted;
  return {
    receiptId: receipt.id,
    type: "expense",
    account_id: accountId ?? "",
    amount: x?.total ?? "",
    merchant: x?.merchant ?? "",
    category_id: x?.suggested_category_id ?? "",
    ...(x?.date ? { date: `${x.date}T12:00` } : {}),
  };
}

export function ReceiptScanDialog({
  open,
  onOpenChange,
  onExtracted,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onExtracted: (draft: TransactionDraft) => void;
}) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <ScanForm onDone={() => onOpenChange(false)} onExtracted={onExtracted} />
      </DialogContent>
    </Dialog>
  );
}

function ScanForm({ onDone, onExtracted }: { onDone: () => void; onExtracted: (draft: TransactionDraft) => void }) {
  const { t } = useI18n();
  const upload = useUploadReceipt();
  const discard = useDeleteReceipt();
  const { data: accounts = [] } = useAccounts();
  const [receiptId, setReceiptId] = useState<string | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const { data: receipt } = useReceipt(receiptId);
  const cameraRef = useRef<HTMLInputElement>(null);
  const fileRef = useRef<HTMLInputElement>(null);

  const processing = upload.isPending || (receiptId !== null && receipt?.status !== "processed" && receipt?.status !== "failed");

  async function choose(file: File | undefined) {
    if (!file) return;
    if (!ACCEPT.split(",").includes(file.type)) return toast.error(t.receipts.unsupported);
    if (file.size > MAX_BYTES) return toast.error(t.receipts.tooLarge);
    setPreview(URL.createObjectURL(file));
    try {
      const created = await upload.mutateAsync(file);
      setReceiptId(created.id);
    } catch (e) {
      toast.error(describeError(e, t));
      setPreview(null);
    }
  }

  function proceed() {
    if (!receipt) return;
    // Prefer an account in the receipt's currency.
    const currency = receipt.extracted?.currency;
    const account = accounts.find((a) => !a.archived && a.currency === currency);
    onExtracted(receiptDraft(receipt, account?.id));
    onDone();
  }

  function cancel() {
    if (receiptId && !receipt?.transaction_id) discard.mutate(receiptId);
    onDone();
  }

  const x = receipt?.extracted;

  return (
    <>
      <DialogHeader>
        <DialogTitle className="flex items-center gap-2">
          <ScanLine className="size-5 text-primary" />
          {t.receipts.scan}
        </DialogTitle>
        <DialogDescription>{t.receipts.description}</DialogDescription>
      </DialogHeader>

      <input ref={cameraRef} type="file" accept={ACCEPT} capture="environment" hidden onChange={(e) => choose(e.target.files?.[0])} />
      <input ref={fileRef} type="file" accept={ACCEPT} hidden onChange={(e) => choose(e.target.files?.[0])} />

      {!preview ? (
        <div className="grid grid-cols-2 gap-3">
          <Button variant="outline" className="h-24 flex-col gap-2" onClick={() => cameraRef.current?.click()}>
            <Camera className="size-6" />
            {t.receipts.takePhoto}
          </Button>
          <Button variant="outline" className="h-24 flex-col gap-2" onClick={() => fileRef.current?.click()}>
            <Upload className="size-6" />
            {t.receipts.upload}
          </Button>
          <p className="col-span-2 text-center text-xs text-muted-foreground">{t.receipts.formats}</p>
        </div>
      ) : (
        <div className="flex gap-4">
          {/* eslint-disable-next-line @next/next/no-img-element -- local object URL preview */}
          <img src={preview} alt={t.receipts.imageAlt} className="h-40 w-28 shrink-0 rounded-md border object-cover" />
          <div className="min-w-0 flex-1 space-y-2 text-sm" aria-live="polite">
            {processing ? (
              <p className="flex items-center gap-2 text-muted-foreground">
                <Loader2 className="size-4 animate-spin" />
                {t.receipts.reading}
              </p>
            ) : receipt?.status === "failed" ? (
              <p className="text-destructive">{receipt.error ?? t.receipts.failed}</p>
            ) : (
              <dl className="space-y-1.5">
                <Row label={t.transactions.merchant} value={x?.merchant} />
                <Row label={t.transactions.amount} value={x?.display_total} ltr />
                <Row label={t.transactions.date} value={x?.date} ltr />
                {x && x.confidence < 1 && <p className="pt-1 text-xs text-amber-600 dark:text-amber-400">{t.receipts.partial}</p>}
              </dl>
            )}
          </div>
        </div>
      )}

      <DialogFooter>
        <Button variant="outline" onClick={cancel}>
          {t.common.cancel}
        </Button>
        {preview && (
          <Button onClick={proceed} disabled={processing || !receipt}>
            {receipt?.status === "failed" ? t.receipts.enterManually : t.receipts.continue}
          </Button>
        )}
      </DialogFooter>
    </>
  );
}

function Row({ label, value, ltr }: { label: string; value?: string | null; ltr?: boolean }) {
  const { t } = useI18n();
  return (
    <div className="flex justify-between gap-2">
      <dt className="text-muted-foreground">{label}</dt>
      <dd className="tabular truncate font-medium" dir={ltr ? "ltr" : undefined}>
        {value || <span className="text-muted-foreground">{t.receipts.notFound}</span>}
      </dd>
    </div>
  );
}
