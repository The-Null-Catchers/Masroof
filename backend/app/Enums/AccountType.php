<?php

namespace App\Enums;

enum AccountType: string
{
    case Cash = 'cash';
    case Bank = 'bank';
    case CreditCard = 'credit_card';
    case Savings = 'savings';
    case EWallet = 'e_wallet';
    case Other = 'other';
}
