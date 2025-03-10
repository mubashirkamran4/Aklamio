# Rewards Service Documentation

## Overview

The `RewardsService` class is a customer reward system that evaluates customer purchases against dynamically added reward rules. It processes purchases and identifies eligible rewards based on the latest matching rule. If we want to add new rules, we can simply add to in the appropriate `REWARD_RULES` category directly in the class to see the output.


## Assumptions
1. Rewards are based on the latest matching rule within each reward category. If multiple purchases qualify for a particular reward, all the purchases are awarded but if multiple purchases qualify for different rewards, only the latest created rule takes priority.

## Class Structure

### `RewardsService`

#### Constants
- `REWARD_RULES`: Defines the available reward rules in three categories:
  1. **`purchase_greater_than_x`**: Rewards based on purchase amount exceeding a threshold.
  2. **`nth_purchase_last_n_days`**: Rewards for the nth purchase within the last N days.
  3. **`purchase_on_nth_date`**: Rewards for a purchase made on a specific day of the month.

- `CUSTOMER_PURCHASES`: Sample purchase data for different customers.

#### Methods

### `evaluate_rewards(purchases)`
- Determines the applicable rewards based on the latest rules.
- Filters eligible purchases for each reward type and selects the latest matching rule.

### Reward Evaluation Methods

1. **`purchase_greater_than_x(purchases, rule)`**
   - Identifies purchases exceeding a specified amount.

2. **`purchase_on_nth_date(purchases, rule)`**
   - Finds purchases made on a specific day of the month.

3. **`nth_purchase_last_n_days(purchases, rule)`**
   - Identifies the nth purchase made within a specified number of days.
   - If fewer purchases than required, no reward is given.

## Test Cases
To execute the test cases simply do `bundle install`
and run 'rspec ./rewards_service_spec.rb' . The comments are already mentioned in test cases to explain.

## Example Usage

```ruby
require './rewards_service.rb'

service = RewardsService.new
service.rewards
```

Output Example:

```
Processing rewards for Customers: 65, 31337, 4465, 234234, 12445, 999
Rewards won for customer 65:
  Rule: {:date_of_purchase=>4, :reward_text=>"Star Wars themed item added to your cart :-)", :created_at=>2025-03-09 23:05:07.420742 UTC}
  Purchases: [{:customer_id=>65, :purchase_amount_cents=>1600, :created_at=>2011-05-04 11:01:00 UTC}]
```

