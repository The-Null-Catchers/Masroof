<?php

return [
    'greeting' => 'Hello :name,',
    'open_app' => 'Open Masroof',
    'budget_threshold' => [
        'title' => ':budget budget at :threshold%',
        'body' => 'You have spent :spent of your :amount :budget budget.',
    ],
    'bill_reminder' => [
        'title' => 'Bill due: :name',
        'body' => ':name (:amount) is due on :date.',
    ],
    'recurring_reminder' => [
        'title' => 'Upcoming payment: :name',
        'body' => ':name (:amount) is scheduled for :date.',
    ],
    'goal_reminder' => [
        'title' => 'Keep :goal on track',
        'body' => ':goal is :percent% funded. Save :monthly per month to reach it on time.',
    ],
    'weekly_summary' => [
        'title' => 'Your week in numbers',
        'body' => 'Last week you earned :income and spent :expense. Top spending: :category.',
    ],
    'monthly_summary' => [
        'title' => 'Your monthly financial summary',
        'body' => 'Last month you earned :income, spent :expense and saved :rate% of your income. Top spending: :category.',
    ],
];
