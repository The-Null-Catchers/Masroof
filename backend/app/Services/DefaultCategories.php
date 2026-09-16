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
    /** Built-in categories treated as fixed (recurring, non-discretionary) costs. */
    public const FIXED = ['rent', 'bills', 'internet', 'mobile', 'subscriptions'];

    public const DEFINITIONS = [
        'food' => ['type' => CategoryType::Expense, 'icon' => 'restaurant', 'color' => '#F97316', 'en' => 'Food', 'ar' => 'الطعام'],
        'restaurants' => ['type' => CategoryType::Expense, 'icon' => 'fastfood', 'color' => '#EA580C', 'en' => 'Restaurants', 'ar' => 'المطاعم'],
        'groceries' => ['type' => CategoryType::Expense, 'icon' => 'shopping_basket', 'color' => '#65A30D', 'en' => 'Groceries', 'ar' => 'البقالة'],
        'transportation' => ['type' => CategoryType::Expense, 'icon' => 'directions_car', 'color' => '#2563EB', 'en' => 'Transportation', 'ar' => 'المواصلات'],
        'fuel' => ['type' => CategoryType::Expense, 'icon' => 'local_gas_station', 'color' => '#0369A1', 'en' => 'Fuel', 'ar' => 'الوقود'],
        'shopping' => ['type' => CategoryType::Expense, 'icon' => 'shopping_bag', 'color' => '#DB2777', 'en' => 'Shopping', 'ar' => 'التسوق'],
        'entertainment' => ['type' => CategoryType::Expense, 'icon' => 'movie', 'color' => '#F59E0B', 'en' => 'Entertainment', 'ar' => 'الترفيه'],
        'bills' => ['type' => CategoryType::Expense, 'icon' => 'receipt', 'color' => '#0891B2', 'en' => 'Bills', 'ar' => 'الفواتير'],
        'internet' => ['type' => CategoryType::Expense, 'icon' => 'wifi', 'color' => '#0EA5E9', 'en' => 'Internet', 'ar' => 'الإنترنت'],
        'mobile' => ['type' => CategoryType::Expense, 'icon' => 'phone_iphone', 'color' => '#6366F1', 'en' => 'Mobile', 'ar' => 'الجوال'],
        'rent' => ['type' => CategoryType::Expense, 'icon' => 'home', 'color' => '#7C3AED', 'en' => 'Rent', 'ar' => 'الإيجار'],
        'healthcare' => ['type' => CategoryType::Expense, 'icon' => 'local_hospital', 'color' => '#DC2626', 'en' => 'Healthcare', 'ar' => 'الرعاية الصحية'],
        'education' => ['type' => CategoryType::Expense, 'icon' => 'school', 'color' => '#4F46E5', 'en' => 'Education', 'ar' => 'التعليم'],
        'travel' => ['type' => CategoryType::Expense, 'icon' => 'flight', 'color' => '#14B8A6', 'en' => 'Travel', 'ar' => 'السفر'],
        'gifts' => ['type' => CategoryType::Expense, 'icon' => 'redeem', 'color' => '#D946EF', 'en' => 'Gifts', 'ar' => 'الهدايا'],
        'subscriptions' => ['type' => CategoryType::Expense, 'icon' => 'subscriptions', 'color' => '#9333EA', 'en' => 'Subscriptions', 'ar' => 'الاشتراكات'],
        'family' => ['type' => CategoryType::Expense, 'icon' => 'family_restroom', 'color' => '#A855F7', 'en' => 'Family', 'ar' => 'العائلة'],
        'other_expense' => ['type' => CategoryType::Expense, 'icon' => 'more_horiz', 'color' => '#64748B', 'en' => 'Other', 'ar' => 'أخرى'],
        'salary' => ['type' => CategoryType::Income, 'icon' => 'payments', 'color' => '#059669', 'en' => 'Salary', 'ar' => 'الراتب'],
        'freelancing' => ['type' => CategoryType::Income, 'icon' => 'work', 'color' => '#0D9488', 'en' => 'Freelancing', 'ar' => 'العمل الحر'],
        'business' => ['type' => CategoryType::Income, 'icon' => 'storefront', 'color' => '#0284C7', 'en' => 'Business', 'ar' => 'الأعمال'],
        'investments' => ['type' => CategoryType::Income, 'icon' => 'trending_up', 'color' => '#16A34A', 'en' => 'Investments', 'ar' => 'الاستثمارات'],
        'gifts_income' => ['type' => CategoryType::Income, 'icon' => 'redeem', 'color' => '#C026D3', 'en' => 'Gifts', 'ar' => 'الهدايا'],
        'refunds' => ['type' => CategoryType::Income, 'icon' => 'currency_exchange', 'color' => '#0891B2', 'en' => 'Refunds', 'ar' => 'المبالغ المستردة'],
        'other_income' => ['type' => CategoryType::Income, 'icon' => 'more_horiz', 'color' => '#64748B', 'en' => 'Other', 'ar' => 'أخرى'],
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
                'is_fixed' => in_array($key, self::FIXED, true),
                'sort_order' => $order++,
            ]);
            $category->default_key = $key;
            $category->save();
        }
    }
}
