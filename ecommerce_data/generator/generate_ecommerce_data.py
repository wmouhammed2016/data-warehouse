"""
E-commerce sample data generator for the data warehouse course.

Generates a relational batch of 7 CSV files with configurable,
intentionally-injected data quality issues: missing values, invalid
values, unwanted whitespace, outliers, inconsistent formats, orphan
foreign keys, and duplicates (both exact reloads and same-key "updated"
rows).

Two entities are deliberately split across two source-like files each,
to simulate integrating data pulled from separate systems:
  - customers.csv          (order/e-commerce system)
  - customer_profiles.csv  (CRM/marketing system -- joins on customer_id,
                             ~92% coverage, some orphan/unmatched rows,
                             and a corrupted key format on some rows)
  - products.csv           (catalog system)
  - product_inventory.csv  (warehouse/supplier system -- joins on
                             product_id, same imperfect-overlap pattern)
  - orders.csv, order_items.csv, payments.csv (order system)

Usage:
    python generate_ecommerce_data.py --batch 1 --seed 42
    python generate_ecommerce_data.py --batch 2 --customers 3000 --orders 12000

Run --help for the full list of tunable options.
"""
import argparse
import random
import string
from pathlib import Path

import numpy as np
import pandas as pd
from faker import Faker

CATEGORIES = {
    "Electronics": ["Phones", "Laptops", "Accessories", "Cameras"],
    "Apparel": ["Men", "Women", "Kids", "Shoes"],
    "Home & Kitchen": ["Furniture", "Appliances", "Decor", "Cookware"],
    "Beauty": ["Skincare", "Makeup", "Haircare"],
    "Sports & Outdoors": ["Fitness", "Camping", "Cycling"],
    "Toys & Games": ["Action Figures", "Board Games", "Puzzles"],
    "Books": ["Fiction", "Non-Fiction", "Children"],
    "Grocery": ["Snacks", "Beverages", "Pantry"],
}
BRANDS = ["Acme", "Nimbus", "Zenith", "Crestline", "Voyager", "Halcyon", "Pinnacle", "Bluepeak"]
ORDER_STATUSES = ["Placed", "Processing", "Shipped", "Delivered", "Cancelled", "Returned"]
ORDER_STATUS_WEIGHTS = [0.15, 0.15, 0.20, 0.35, 0.10, 0.05]
CHANNELS = ["Web", "Mobile App", "Marketplace", "In-Store"]
CHANNEL_WEIGHTS = [0.40, 0.35, 0.15, 0.10]
PAYMENT_METHODS = ["Credit Card", "Debit Card", "PayPal", "Gift Card", "Bank Transfer"]
PAYMENT_METHOD_WEIGHTS = [0.40, 0.25, 0.20, 0.10, 0.05]
PAYMENT_STATUSES = ["Completed", "Pending", "Failed", "Refunded"]
PAYMENT_STATUS_WEIGHTS = [0.80, 0.10, 0.05, 0.05]
COUNTRY_VARIANTS = ["United States", "USA", "US", "U.S.A."]
US_STATES = ["CA", "TX", "NY", "FL", "WA", "IL", "PA", "OH", "GA", "NC", "MI", "AZ"]


def build_customers(n, fake, rng):
    ids = [f"CUST-{i:06d}" for i in range(1, n + 1)]
    signup_dates = [fake.date_between(start_date="-3y", end_date="today") for _ in range(n)]
    rows = []
    for i in range(n):
        first = fake.first_name()
        last = fake.last_name()
        rows.append({
            "customer_id": ids[i],
            "first_name": first,
            "last_name": last,
            "email": f"{first.lower()}.{last.lower()}{rng.integers(1, 999)}@{fake.free_email_domain()}",
            "phone": fake.numerify("###-###-####"),
            "signup_date": signup_dates[i].isoformat(),
            "city": fake.city(),
            "state": rng.choice(US_STATES),
            "country": rng.choice(COUNTRY_VARIANTS, p=[0.7, 0.15, 0.1, 0.05]),
        })
    return pd.DataFrame(rows)


def build_products(n, fake, rng):
    rows = []
    cats = list(CATEGORIES.keys())
    for i in range(1, n + 1):
        cat = rng.choice(cats)
        sub = rng.choice(CATEGORIES[cat])
        cost = round(rng.uniform(3, 400), 2)
        margin = rng.uniform(1.3, 2.5)
        rows.append({
            "product_id": f"PROD-{i:05d}",
            "product_name": f"{rng.choice(BRANDS)} {sub} {fake.word().title()}",
            "category": cat,
            "sub_category": sub,
            "brand": rng.choice(BRANDS),
            "unit_price": round(cost * margin, 2),
            "cost_price": cost,
        })
    return pd.DataFrame(rows)


def build_orders(n, customers_df, fake, rng):
    signup_lookup = dict(zip(customers_df["customer_id"], pd.to_datetime(customers_df["signup_date"])))
    cust_ids = customers_df["customer_id"].tolist()
    rows = []
    for i in range(1, n + 1):
        cust = rng.choice(cust_ids)
        earliest = signup_lookup[cust]
        order_dt = fake.date_between(start_date=earliest.date(), end_date="today")
        rows.append({
            "order_id": f"ORD-{i:07d}",
            "customer_id": cust,
            "order_date": order_dt.isoformat(),
            "order_status": rng.choice(ORDER_STATUSES, p=ORDER_STATUS_WEIGHTS),
            "channel": rng.choice(CHANNELS, p=CHANNEL_WEIGHTS),
            "shipping_city": fake.city(),
            "shipping_state": rng.choice(US_STATES),
        })
    return pd.DataFrame(rows)


def build_order_items(orders_df, products_df, rng):
    prod_ids = products_df["product_id"].tolist()
    prod_price = dict(zip(products_df["product_id"], products_df["unit_price"]))
    rows = []
    item_counter = 1
    for order_id in orders_df["order_id"]:
        n_items = rng.choice([1, 2, 3, 4], p=[0.45, 0.30, 0.18, 0.07])
        chosen = rng.choice(prod_ids, size=n_items, replace=False)
        for pid in chosen:
            base_price = prod_price[pid]
            price = round(float(base_price) * rng.uniform(0.95, 1.05), 2)
            discount = rng.choice([0, 0, 0, 0.05, 0.10, 0.15, 0.20], p=[0.4, 0.15, 0.15, 0.1, 0.1, 0.05, 0.05])
            rows.append({
                "order_item_id": f"OI-{item_counter:07d}",
                "order_id": order_id,
                "product_id": pid,
                "quantity": int(rng.choice([1, 1, 1, 2, 2, 3, 4, 5])),
                "unit_price": price,
                "discount_pct": discount,
            })
            item_counter += 1
    return pd.DataFrame(rows)


def build_customer_profiles(customers_df, fake, rng, coverage=0.92):
    cust_ids = customers_df["customer_id"].tolist()
    emails = dict(zip(customers_df["customer_id"], customers_df["email"]))
    n_cover = int(len(cust_ids) * coverage)
    covered = list(rng.choice(cust_ids, size=n_cover, replace=False))
    n_orphan = max(1, int(len(cust_ids) * 0.02))
    orphan_ids = [f"CUST-{int(rng.integers(900000, 999999)):06d}" for _ in range(n_orphan)]
    all_ids = covered + orphan_ids
    order = rng.permutation(len(all_ids))
    all_ids = [all_ids[i] for i in order]

    rows = []
    for i, cid in enumerate(all_ids, start=1):
        email = emails.get(cid, fake.email())
        rows.append({
            "profile_id": f"CRMP-{i:06d}",
            "customer_id": cid,
            "email": email,
            "loyalty_tier": rng.choice(["Bronze", "Silver", "Gold", "Platinum"], p=[0.4, 0.3, 0.2, 0.1]),
            "marketing_opt_in": rng.choice(["Yes", "No"], p=[0.6, 0.4]),
            "preferred_channel": rng.choice(CHANNELS, p=CHANNEL_WEIGHTS),
            "birth_date": fake.date_of_birth(minimum_age=18, maximum_age=85).isoformat(),
            "gender": rng.choice(["Female", "Male", "Non-binary", "Prefer not to say"], p=[0.45, 0.45, 0.05, 0.05]),
        })
    return pd.DataFrame(rows)


def build_product_inventory(products_df, fake, rng, coverage=0.92):
    prod_ids = products_df["product_id"].tolist()
    n_cover = int(len(prod_ids) * coverage)
    covered = list(rng.choice(prod_ids, size=n_cover, replace=False))
    n_orphan = max(1, int(len(prod_ids) * 0.03))
    orphan_ids = [f"PROD-{int(rng.integers(90000, 99999)):05d}" for _ in range(n_orphan)]
    all_ids = covered + orphan_ids
    order = rng.permutation(len(all_ids))
    all_ids = [all_ids[i] for i in order]

    warehouses = ["WH-EAST-01", "WH-WEST-02", "WH-CENTRAL-03", "WH-SOUTH-04"]
    rows = []
    for i, pid in enumerate(all_ids, start=1):
        rows.append({
            "inventory_id": f"INV-{i:06d}",
            "product_id": pid,
            "warehouse_location": rng.choice(warehouses),
            "stock_quantity": int(rng.integers(0, 500)),
            "reorder_level": int(rng.integers(10, 100)),
            "supplier_name": fake.company(),
            "last_restock_date": fake.date_between(start_date="-1y", end_date="today").isoformat(),
        })
    return pd.DataFrame(rows)


def build_payments(orders_df, items_df, fake, rng):
    order_dates = dict(zip(orders_df["order_id"], pd.to_datetime(orders_df["order_date"])))
    order_status = dict(zip(orders_df["order_id"], orders_df["order_status"]))
    totals = items_df.assign(
        line_total=items_df["quantity"] * items_df["unit_price"] * (1 - items_df["discount_pct"])
    ).groupby("order_id")["line_total"].sum().round(2)

    rows = []
    for i, (order_id, amount) in enumerate(totals.items(), start=1):
        status = order_status[order_id]
        pay_status = "Refunded" if status == "Returned" else ("Failed" if status == "Cancelled" else
                     rng.choice(PAYMENT_STATUSES, p=PAYMENT_STATUS_WEIGHTS))
        pay_date = order_dates[order_id] + pd.Timedelta(days=int(rng.integers(0, 4)))
        rows.append({
            "payment_id": f"PAY-{i:07d}",
            "order_id": order_id,
            "payment_method": rng.choice(PAYMENT_METHODS, p=PAYMENT_METHOD_WEIGHTS),
            "amount": amount,
            "payment_date": pay_date.date().isoformat(),
            "payment_status": pay_status,
        })
    return pd.DataFrame(rows)


# ---------------------------------------------------------------------------
# Dirtiness injection -- operates on string-cast columns, mutating in place.
# ---------------------------------------------------------------------------

def pick_indices(n, rate, rng):
    k = int(n * rate)
    if k == 0:
        return np.array([], dtype=int)
    return rng.choice(n, size=k, replace=False)


def inject_missing(df, col, rate, rng):
    for idx in pick_indices(len(df), rate, rng):
        df.at[idx, col] = ""


def inject_whitespace(df, col, rate, rng):
    for idx in pick_indices(len(df), rate, rng):
        val = str(df.at[idx, col])
        style = rng.integers(0, 3)
        if style == 0:
            df.at[idx, col] = f"  {val}"
        elif style == 1:
            df.at[idx, col] = f"{val}   "
        else:
            df.at[idx, col] = val.replace(" ", "  ", 1) if " " in val else f" {val} "


def inject_case_noise(df, col, rate, rng):
    for idx in pick_indices(len(df), rate, rng):
        val = str(df.at[idx, col])
        style = rng.integers(0, 3)
        df.at[idx, col] = val.upper() if style == 0 else (val.lower() if style == 1 else val.swapcase())


def inject_invalid_numeric(df, col, rate, rng):
    garbage_pool = ["N/A", "unknown", "--", "null", "n/a", "?"]
    for idx in pick_indices(len(df), rate, rng):
        style = rng.integers(0, 4)
        if style == 0:
            df.at[idx, col] = rng.choice(garbage_pool)
        elif style == 1:
            try:
                df.at[idx, col] = str(-abs(float(df.at[idx, col])))
            except ValueError:
                df.at[idx, col] = "-1"
        elif style == 2:
            df.at[idx, col] = f"${df.at[idx, col]}"
        else:
            df.at[idx, col] = str(df.at[idx, col]) + "abc"


def inject_outliers(df, col, rate, rng, multiplier=(20, 100)):
    for idx in pick_indices(len(df), rate, rng):
        try:
            val = float(df.at[idx, col])
        except ValueError:
            continue
        df.at[idx, col] = str(round(val * rng.uniform(*multiplier), 2))


def inject_invalid_email(df, col, rate, rng):
    for idx in pick_indices(len(df), rate, rng):
        val = str(df.at[idx, col])
        style = rng.integers(0, 3)
        if style == 0:
            df.at[idx, col] = val.replace("@", "_at_")
        elif style == 1:
            df.at[idx, col] = val.split("@")[0] if "@" in val else val
        else:
            df.at[idx, col] = val.replace(".com", "").replace(".net", "").replace(".org", "")


def inject_date_format_noise(df, col, rate, rng):
    for idx in pick_indices(len(df), rate, rng):
        try:
            d = pd.to_datetime(df.at[idx, col])
        except (ValueError, TypeError):
            continue
        style = rng.integers(0, 3)
        if style == 0:
            df.at[idx, col] = d.strftime("%m/%d/%Y")
        elif style == 1:
            df.at[idx, col] = d.strftime("%d-%b-%Y")
        else:
            df.at[idx, col] = d.strftime("%B %d, %Y")


def inject_key_format_noise(df, col, rate, rng):
    """Corrupts the *format* of a foreign/join key (strip prefix, lowercase
    prefix, drop the hyphen) without destroying the underlying id -- this is
    what forces a real key-normalization step before joining two sources."""
    for idx in pick_indices(len(df), rate, rng):
        val = str(df.at[idx, col])
        if "-" not in val:
            continue
        prefix, _, num = val.partition("-")
        style = rng.integers(0, 3)
        if style == 0:
            df.at[idx, col] = num
        elif style == 1:
            df.at[idx, col] = f"{prefix.lower()}-{num}"
        else:
            df.at[idx, col] = f"{prefix}{num}"


def inject_orphan_fk(df, col, rate, rng, prefix, width):
    for idx in pick_indices(len(df), rate, rng):
        fake_id = int(rng.integers(900000, 999999))
        df.at[idx, col] = f"{prefix}-{fake_id:0{width}d}"


def duplicate_rows(df, exact_rate, updated_rate, rng, mutable_col=None):
    n = len(df)
    exact_idx = pick_indices(n, exact_rate, rng)
    exact_dupes = df.iloc[exact_idx].copy()

    updated_dupes = pd.DataFrame(columns=df.columns)
    if mutable_col is not None and updated_rate > 0:
        upd_idx = pick_indices(n, updated_rate, rng)
        updated_dupes = df.iloc[upd_idx].copy()
        for idx in updated_dupes.index:
            updated_dupes.at[idx, mutable_col] = _mutate_value(df.at[idx, mutable_col], mutable_col, rng)

    combined = pd.concat([df, exact_dupes, updated_dupes], ignore_index=True)
    return combined.sample(frac=1, random_state=int(rng.integers(0, 1_000_000))).reset_index(drop=True)


def _mutate_value(value, col_name, rng):
    if col_name in ("order_status",):
        return rng.choice(ORDER_STATUSES)
    if col_name in ("payment_status",):
        return rng.choice(PAYMENT_STATUSES)
    try:
        return str(round(float(value) * rng.uniform(0.8, 1.2), 2))
    except (ValueError, TypeError):
        return value


def stringify(df):
    out = df.copy()
    for col in out.columns:
        out[col] = out[col].astype(str)
    return out


def main():
    parser = argparse.ArgumentParser(description="Generate a dirty, relational e-commerce data batch.")
    parser.add_argument("--customers", type=int, default=3000)
    parser.add_argument("--products", type=int, default=300)
    parser.add_argument("--orders", type=int, default=12000)
    parser.add_argument("--dirty-rate", type=float, default=0.04, help="Base rate applied to each dirtiness category per column.")
    parser.add_argument("--exact-dupe-rate", type=float, default=0.03)
    parser.add_argument("--updated-dupe-rate", type=float, default=0.02)
    parser.add_argument("--orphan-fk-rate", type=float, default=0.02)
    parser.add_argument("--customer-profile-coverage", type=float, default=0.92)
    parser.add_argument("--product-inventory-coverage", type=float, default=0.92)
    parser.add_argument("--batch", type=int, default=1)
    parser.add_argument("--seed", type=int, default=None)
    parser.add_argument("--output-dir", type=str, default=str(Path(__file__).resolve().parent.parent / "batches"))
    args = parser.parse_args()

    seed = args.seed if args.seed is not None else random.randint(0, 1_000_000)
    rng = np.random.default_rng(seed)
    fake = Faker()
    Faker.seed(seed)

    print(f"Generating batch {args.batch} with seed={seed}")

    customers_df = build_customers(args.customers, fake, rng)
    products_df = build_products(args.products, fake, rng)
    orders_df = build_orders(args.orders, customers_df, fake, rng)
    items_df = build_order_items(orders_df, products_df, rng)
    payments_df = build_payments(orders_df, items_df, fake, rng)
    profiles_df = build_customer_profiles(customers_df, fake, rng, args.customer_profile_coverage)
    inventory_df = build_product_inventory(products_df, fake, rng, args.product_inventory_coverage)

    customers_s = stringify(customers_df)
    products_s = stringify(products_df)
    orders_s = stringify(orders_df)
    items_s = stringify(items_df)
    payments_s = stringify(payments_df)
    profiles_s = stringify(profiles_df)
    inventory_s = stringify(inventory_df)

    dr = args.dirty_rate

    inject_missing(customers_s, "phone", dr, rng)
    inject_missing(customers_s, "city", dr, rng)
    inject_whitespace(customers_s, "first_name", dr, rng)
    inject_whitespace(customers_s, "last_name", dr, rng)
    inject_whitespace(customers_s, "email", dr, rng)
    inject_invalid_email(customers_s, "email", dr, rng)
    inject_case_noise(customers_s, "state", dr, rng)
    inject_date_format_noise(customers_s, "signup_date", dr, rng)

    inject_missing(products_s, "brand", dr, rng)
    inject_whitespace(products_s, "product_name", dr, rng)
    inject_case_noise(products_s, "category", dr, rng)
    inject_invalid_numeric(products_s, "unit_price", dr, rng)
    inject_outliers(products_s, "cost_price", dr / 2, rng)

    inject_missing(orders_s, "customer_id", dr / 2, rng)
    inject_missing(orders_s, "shipping_city", dr, rng)
    inject_case_noise(orders_s, "order_status", dr, rng)
    inject_date_format_noise(orders_s, "order_date", dr, rng)
    inject_orphan_fk(orders_s, "customer_id", args.orphan_fk_rate, rng, "CUST", 6)

    inject_invalid_numeric(items_s, "quantity", dr, rng)
    inject_invalid_numeric(items_s, "unit_price", dr, rng)
    inject_outliers(items_s, "unit_price", dr / 2, rng)
    inject_orphan_fk(items_s, "product_id", args.orphan_fk_rate, rng, "PROD", 5)
    inject_orphan_fk(items_s, "order_id", args.orphan_fk_rate, rng, "ORD", 7)

    inject_missing(payments_s, "payment_method", dr, rng)
    inject_invalid_numeric(payments_s, "amount", dr, rng)
    inject_outliers(payments_s, "amount", dr / 2, rng)
    inject_date_format_noise(payments_s, "payment_date", dr, rng)
    inject_orphan_fk(payments_s, "order_id", args.orphan_fk_rate, rng, "ORD", 7)

    inject_missing(profiles_s, "loyalty_tier", dr, rng)
    inject_whitespace(profiles_s, "email", dr, rng)
    inject_case_noise(profiles_s, "email", dr, rng)
    inject_case_noise(profiles_s, "gender", dr, rng)
    inject_date_format_noise(profiles_s, "birth_date", dr, rng)
    inject_key_format_noise(profiles_s, "customer_id", dr * 1.5, rng)

    inject_missing(inventory_s, "supplier_name", dr, rng)
    inject_invalid_numeric(inventory_s, "stock_quantity", dr, rng)
    inject_outliers(inventory_s, "stock_quantity", dr / 2, rng)
    inject_date_format_noise(inventory_s, "last_restock_date", dr, rng)
    inject_key_format_noise(inventory_s, "product_id", dr * 1.5, rng)

    customers_s = duplicate_rows(customers_s, args.exact_dupe_rate, args.updated_dupe_rate, rng, mutable_col="phone")
    products_s = duplicate_rows(products_s, args.exact_dupe_rate, args.updated_dupe_rate, rng, mutable_col="unit_price")
    orders_s = duplicate_rows(orders_s, args.exact_dupe_rate, args.updated_dupe_rate, rng, mutable_col="order_status")
    items_s = duplicate_rows(items_s, args.exact_dupe_rate, args.updated_dupe_rate, rng, mutable_col="quantity")
    payments_s = duplicate_rows(payments_s, args.exact_dupe_rate, args.updated_dupe_rate, rng, mutable_col="payment_status")
    profiles_s = duplicate_rows(profiles_s, args.exact_dupe_rate, args.updated_dupe_rate, rng, mutable_col="loyalty_tier")
    inventory_s = duplicate_rows(inventory_s, args.exact_dupe_rate, args.updated_dupe_rate, rng, mutable_col="stock_quantity")

    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    suffix = f"_batch{args.batch}"
    customers_s.to_csv(out_dir / f"customers{suffix}.csv", index=False)
    products_s.to_csv(out_dir / f"products{suffix}.csv", index=False)
    orders_s.to_csv(out_dir / f"orders{suffix}.csv", index=False)
    items_s.to_csv(out_dir / f"order_items{suffix}.csv", index=False)
    payments_s.to_csv(out_dir / f"payments{suffix}.csv", index=False)
    profiles_s.to_csv(out_dir / f"customer_profiles{suffix}.csv", index=False)
    inventory_s.to_csv(out_dir / f"product_inventory{suffix}.csv", index=False)

    print(f"customers: {len(customers_s)} rows")
    print(f"products: {len(products_s)} rows")
    print(f"orders: {len(orders_s)} rows")
    print(f"order_items: {len(items_s)} rows")
    print(f"payments: {len(payments_s)} rows")
    print(f"customer_profiles: {len(profiles_s)} rows")
    print(f"product_inventory: {len(inventory_s)} rows")
    print(f"Written to {out_dir.resolve()}")


if __name__ == "__main__":
    main()
