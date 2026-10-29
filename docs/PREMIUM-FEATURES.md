# Premium features

Staff Portal · © cmeproject

Some features are add-ons that cmeproject includes in a company's plan.
Once a feature is included, the company's system admin switches it on or
off under **System settings → Features**. A feature that isn't included shows
as **Locked** ("Not included in your plan"), and the database blocks it.

| Feature | Key | Premium |
|---|---|---|
| Cars (company cars, trips, mileage, Cars app) | `vehicles` | Yes |

## Including or removing a feature for a company

Run in that company's Supabase SQL Editor (only cmeproject does this; the
portal itself can't change a company's plan):

```sql
-- Include Cars in the plan (the system admin can then switch it on)
update public.features set included = true where key = 'vehicles';

-- Take Cars out of the plan (switches it off and locks it)
update public.features set included = false, enabled = false where key = 'vehicles';
```

Records are never deleted: trips and cars stay in the database and come back
if the feature is included again.
