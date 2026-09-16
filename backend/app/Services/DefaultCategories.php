<?php

namespace App\Services;

use App\Enums\CategoryType;
use App\Models\User;

/**
 * Starter categories created for every new user. Names are stored in the
 * user's locale; `default_key` lets clients re-localize until renamed.
 */
class DefaultCategories
{
    /** @var array<string, array{type: CategoryType, icon: string, color: string, en: string, ar: string}> */
    public const DEFINITIONS = [
        'food' => ['type' => CategoryType::Expense, 'icon' => 'restaurant', 'color' => '#F97316', 'en' => 'Food & Dining', 'ar' => 'الطعام والمطاعم'],
        'groceries' => ['type' => CategoryType::Expense, 'icon' => 'shopping_basket', 'color' => '#84CC16', 'en' => 'Groceries', 'ar' => 'البقالة'],
        'transport' => ['type' => CategoryType::Expense, 'icon' => 'directions_car', 'color' => '#3B82F6', 'en' => 'Transport', 'ar' => 'المواصلات'],
        'housing' => ['type' => CategoryType::Expense, 'icon' => 'home', 'color' => '#8B5CF6', 'en' => 'Housing & Rent', 'ar' => 'السكن والإيجار'],
        'bills' => ['type' => CategoryType::Expense, 'icon' => 'receipt', 'color' => '#06B6D4', 'en' => 'Bills & Utilities', 'ar' => 'الفواتير والخدمات'],
        'shopping' => ['type' => CategoryType::Expense, 'icon' => 'shopping_bag', 'color' => '#EC4899', 'en' => 'Shopping', 'ar' => 'التسوق'],
        'health' => ['type' => CategoryType::Expense, 'icon' => 'favorite', 'color' => '#EF4444', 'en' => 'Health', 'ar' => 'الصحة'],
        'education' => ['type' => CategoryType::Expense, 'icon' => 'school', 'color' => '#6366F1', 'en' => 'Education', 'ar' => 'التعليم'],
        'entertainment' => ['type' => CategoryType::Expense, 'icon' => 'movie', 'color' => '#F59E0B', 'en' => 'Entertainment', 'ar' => 'الترفيه'],
        'travel' => ['type' => CategoryType::Expense, 'icon' => 'flight', 'color' => '#14B8A6', 'en' => 'Travel', 'ar' => 'السفر'],
        'charity' => ['type' => CategoryType::Expense, 'icon' => 'volunteer_activism', 'color' => '#10B981', 'en' => 'Charity & Zakat', 'ar' => 'الصدقات والزكاة'],
        'family' => ['type' => CategoryType::Expense, 'icon' => 'family_restroom', 'color' => '#A855F7', 'en' => 'Family', 'ar' => 'العائلة'],
        'other_expense' => ['type' => CategoryType::Expense, 'icon' => 'more_horiz', 'color' => '#64748B', 'en' => 'Other', 'ar' => 'أخرى'],
        'salary' => ['type' => CategoryType::Income, 'icon' => 'payments', 'color' => '#059669', 'en' => 'Salary', 'ar' => 'الراتب'],
        'business' => ['type' => CategoryType::Income, 'icon' => 'storefront', 'color' => '#0EA5E9', 'en' => 'Business', 'ar' => 'الأعمال'],
        'gifts' => ['type' => CategoryType::Income, 'icon' => 'redeem', 'color' => '#D946EF', 'en' => 'Gifts', 'ar' => 'الهدايا'],
        'investments' => ['type' => CategoryType::Income, 'icon' => 'trending_up', 'color' => '#22C55E', 'en' => 'Investments', 'ar' => 'الاستثمارات'],
        'other_income' => ['type' => CategoryType::Income, 'icon' => 'more_horiz', 'color' => '#64748B', 'en' => 'Other income', 'ar' => 'دخل آخر'],
    ];

    public function provision(User $user): void
    {
        $locale = in_array($user->locale, ['ar', 'en'], true) ? $user->locale : 'en';
        $order = 0;

        foreach (self::DEFINITIONS as $key => $definition) {
            $category = $user->categories()->make([
                'name' => $definition[$locale],
                'type' => $definition['type'],
                'icon' => $definition['icon'],
                'color' => $definition['color'],
                'sort_order' => $order++,
            ]);
            $category->default_key = $key;
            $category->save();
        }
    }
}
