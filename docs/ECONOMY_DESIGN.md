# Economy

All money and item transactions use integer quantities. Commands reject insufficient stock/cash, nonpositive trade quantities and duplicate claims before mutation. Inventory has a base 400-unit cap, expanded by completed connected warehouses. Output pauses at capacity or when inputs are missing; recipes exchange input/output atomically.

Sale price = base price × clamped stock scarcity × research multiplier × event multiplier, rounded down and bounded to one. Buy prices round up a 1.25 markup. Feed can be purchased or processed from corn in the feed mill; paddy-to-rice, soy-to-tofu/tempe and lumber chains are implemented. Seed purchases keep farms renewable.

Crop moisture falls during growth; dry fields pause until manually watered, rain arrives or local water coverage replenishes them. Animal health reduces output when feed is unavailable; feeding restores health.

Every 120 seconds employed workers generate Rp 9 each, buildings consume maintenance and residents consume rice (ceil(population × 0.04), at least one). Cash bottoms at zero instead of accumulating unrecoverable debt. Available housing, food and happiness gate migration. Worker/job ratio scales processing efficiency, with a 25% floor to preserve recovery. Rain and dry spells affect growth; festivals/tourism affect prices; floods/labor shortages slow production temporarily.

All numbers live in `data/*.json`. A 60-day scripted scenario checks nonnegative stock/money and a viable population. This is a correctness smoke scenario, not evidence of complete long-term balance.
