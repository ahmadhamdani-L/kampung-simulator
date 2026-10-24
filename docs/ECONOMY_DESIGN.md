# Economy

All money and item transactions use integer quantities. Commands reject insufficient stock/cash, nonpositive trade quantities and duplicate claims before mutation. Inventory has a base 400-unit cap, expanded by completed connected warehouses. Output pauses at capacity or when inputs are missing; recipes exchange input/output atomically.

Sale price = base price × clamped stock scarcity × research multiplier × event multiplier, rounded down and bounded to one. Buy prices round up a 1.25 markup. Animal feed is a purchased resource in this candidate. Corn-to-feed processing and paddy-to-rice production are intended expansion points; the rice mill and soy chains are implemented. Seed purchases keep farms renewable.

Every 120 seconds employed workers generate Rp 9 each, buildings consume maintenance and residents consume rice (ceil(population × 0.04), at least one). Cash bottoms at zero instead of accumulating unrecoverable debt. Available housing, food and happiness gate migration. Worker/job ratio scales processing efficiency, with a 25% floor to preserve recovery. Rain and dry spells affect growth; festivals/tourism affect prices; floods/labor shortages slow production temporarily.

All numbers live in `data/*.json`. A 60-day scripted scenario checks nonnegative stock/money and a viable population. This is a correctness smoke scenario, not evidence of complete long-term balance.
