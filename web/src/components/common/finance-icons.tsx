import {
  Baby,
  BadgeDollarSign,
  Banknote,
  Car,
  CircleEllipsis,
  Clapperboard,
  CreditCard,
  Dumbbell,
  Fuel,
  Gift,
  GraduationCap,
  HandHeart,
  Heart,
  Home,
  Landmark,
  PawPrint,
  PiggyBank,
  Plane,
  Receipt,
  Shirt,
  ShoppingBag,
  ShoppingBasket,
  Smartphone,
  Store,
  Tag,
  TrendingUp,
  Users,
  Utensils,
  Wallet,
  Coffee,
  type LucideIcon,
} from "lucide-react";

import type { AccountType } from "@/lib/types";

/** Icon identifiers shared with the API and the mobile app. */
export const CATEGORY_ICONS: Record<string, LucideIcon> = {
  restaurant: Utensils,
  shopping_basket: ShoppingBasket,
  directions_car: Car,
  home: Home,
  receipt: Receipt,
  shopping_bag: ShoppingBag,
  favorite: Heart,
  school: GraduationCap,
  movie: Clapperboard,
  flight: Plane,
  volunteer_activism: HandHeart,
  family_restroom: Users,
  more_horiz: CircleEllipsis,
  payments: Banknote,
  storefront: Store,
  redeem: Gift,
  trending_up: TrendingUp,
  local_cafe: Coffee,
  fitness_center: Dumbbell,
  pets: PawPrint,
  phone_iphone: Smartphone,
  local_gas_station: Fuel,
  checkroom: Shirt,
  child_care: Baby,
  account_balance: Landmark,
  account_balance_wallet: Wallet,
  credit_card: CreditCard,
  savings: PiggyBank,
  wallet: Wallet,
  category: Tag,
};

export const ACCOUNT_TYPE_ICONS: Record<AccountType, LucideIcon> = {
  cash: Banknote,
  bank: Landmark,
  credit_card: CreditCard,
  savings: PiggyBank,
  e_wallet: Wallet,
  other: BadgeDollarSign,
};

export const PALETTE = ["#0F7A68", "#2563EB", "#7C3AED", "#DB2777", "#DC2626", "#F97316", "#F5B83D", "#65A30D", "#0891B2", "#475569"];

export function IconBadge({ icon: Icon, color, size = 36 }: { icon: LucideIcon; color?: string | null; size?: number }) {
  const tint = color ?? "var(--primary)";
  return (
    <span
      className="grid shrink-0 place-items-center rounded-[30%]"
      style={{ width: size, height: size, color: tint, background: `color-mix(in oklch, ${tint} 14%, transparent)` }}
    >
      <Icon style={{ width: size * 0.5, height: size * 0.5 }} />
    </span>
  );
}
