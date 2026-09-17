<?php

namespace App\Services\Ocr;

use App\Models\User;

/**
 * Suggests an expense category for a merchant: first from the user's own
 * history with that merchant, then from keywords mapped to built-in categories.
 */
class CategorySuggester
{
    private const KEYWORDS = [
        'groceries' => ['supermarket', 'market', 'grocery', 'bravo', 'سوبرماركت', 'ماركت', 'بقالة', 'تموينات'],
        'restaurants' => ['restaurant', 'cafe', 'café', 'coffee', 'pizza', 'burger', 'falafel', 'grill', 'مطعم', 'مقهى', 'كافيه', 'فلافل', 'شاورما'],
        'fuel' => ['fuel', 'petrol', 'gas station', 'paz', 'محطة', 'وقود', 'بنزين'],
        'healthcare' => ['pharmacy', 'clinic', 'hospital', 'صيدلية', 'عيادة', 'مستشفى'],
        'shopping' => ['mall', 'store', 'fashion', 'zara', 'ikea', 'متجر', 'مول', 'أزياء'],
        'transportation' => ['taxi', 'bus', 'uber', 'تاكسي', 'حافلة', 'مواصلات'],
        'bills' => ['electric', 'water', 'كهرباء', 'مياه'],
        'internet' => ['internet', 'paltel', 'انترنت', 'إنترنت'],
        'mobile' => ['jawwal', 'ooredoo', 'جوال', 'اتصالات'],
        'education' => ['book', 'school', 'university', 'مكتبة', 'مدرسة', 'جامعة'],
        'entertainment' => ['cinema', 'movie', 'سينما'],
    ];

    public function suggest(User $user, ?string $merchant): ?string
    {
        if ($merchant === null || trim($merchant) === '') {
            return null;
        }

        $fromHistory = $user->transactions()
            ->where('type', 'expense')
            ->whereNotNull('category_id')
            ->whereRaw('lower(merchant) = ?', [mb_strtolower(trim($merchant))])
            ->selectRaw('category_id, COUNT(*) AS uses')
            ->groupBy('category_id')
            ->orderByDesc('uses')
            ->value('category_id');
        if ($fromHistory !== null) {
            return $fromHistory;
        }

        $lower = mb_strtolower($merchant);
        foreach (self::KEYWORDS as $key => $words) {
            foreach ($words as $word) {
                if (str_contains($lower, $word)) {
                    return $user->categories()->where('default_key', $key)->whereNull('archived_at')->value('id');
                }
            }
        }

        return null;
    }
}
