<?php

namespace Database\Factories;

use App\Enums\CategoryType;
use App\Models\Category;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Category>
 */
class CategoryFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'name' => fake()->word(),
            'type' => CategoryType::Expense,
            'color' => '#64748B',
            'icon' => 'category',
        ];
    }

    public function income(): static
    {
        return $this->state(fn () => ['type' => CategoryType::Income]);
    }
}
